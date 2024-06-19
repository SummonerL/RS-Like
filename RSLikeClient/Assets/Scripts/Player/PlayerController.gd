extends Node3D

# Array to store the movement path for the player
var movement_path = [] # Vector2

# Our global Refs
@export var __: Refs

# Reference to the terrain RayCast (used for determining terrain height)
@export var terrain_cast: RayCast3D

# Clean this up. We want to attach the MeshInstance3D
var mesh: MeshInstance3D

func _ready():
	# Connect to the tick signal
	GameManager.connect("tick", _on_tick)
	
	# Server requests to set (teleport) the player position
	__.game_server.connect("update_player_position", teleport_to_cell)
	__.entity_manager.connect("process_self", _on_self_entity_updated)
	
	mesh = get_node("/root/Main/GameViewportContainer/GameViewport/MalePlayer/Cube")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("left_click"):
		var target_position = get_viewport().get_mouse_position()
		generic_action_request(target_position)
		
# 'Generic', or default action, depending on the location or object clicked on.
# Note that we want to identify the target cell before the tick, so that the proper request is mad.e
func generic_action_request(target_position):
	
	# We need to raycast to determine the point on the GridMap where the user clicked. Naturally,
	# this depends on the camera.
	var from = __.camera.project_ray_origin(target_position)
	var to = from + __.camera.project_ray_normal(target_position) * 1000 # A far enough distance
	
	var space_state = __.camera.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	var result = space_state.intersect_ray(params)
	
	if result:
		var intersection_point = result.position
		intersection_point.y = 0
		
		# convert intersection point to GridMap coordinate
		var target_grid_map_coordinate = __.world_grid.local_to_map(intersection_point)
		
		# ensure the target is within the maximum click distance
		var player_current_tile = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
		if (__.world_grid.get_distance(player_current_tile, target_grid_map_coordinate) > GameManager.MAX_CLICK_DISTANCE):
			return
		
		# set the click flag to this position (actual position, not the grid coordinate)
		__.click_flag.move_flag(intersection_point)
		
		# submit the request to the server
		__.game_server.send_player_request(Constants.REQUEST_TYPE.MOVE, Vector2(target_grid_map_coordinate.x, target_grid_map_coordinate.z))
	
func process_movement(target_cell: Vector2):
	
	var source_cell = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	
	# TODO: The server should ideally determine the movement path.
	movement_path = __.world_grid.find_path(Vector2(source_cell.x, source_cell.z), target_cell)
	
func move_to_cell(grid_cell):
	var target = __.world_grid.map_to_local_center(grid_cell)
	var move_c = move_coroutine(target)
	move_c.call()
	
func teleport_to_cell(grid_cell):
	global_transform.origin = __.world_grid.map_to_local_center(grid_cell)
	snap_to_terrain()

# update the y position to match the terrain
func snap_to_terrain():
		terrain_cast.enabled = true # determine terrain height
		
		terrain_cast.force_raycast_update()
		if (terrain_cast.is_colliding()):
			global_transform.origin.y = terrain_cast.get_collision_point().y

		terrain_cast.enabled = false

	
func move_coroutine(target):
	return func() -> void:
		var elapsed_time = 0.0
		var start_position = global_transform.origin
		var start_rotation = mesh.rotation
		var direction = (target - start_position).normalized()
		var target_rotation = Basis.looking_at(direction, Vector3.UP, true).get_euler()
		terrain_cast.enabled = true # determine terrain height
		target.y = 0

		while elapsed_time < GameManager.TICK_INTERVAL:
			elapsed_time += get_process_delta_time()
			var t = elapsed_time / GameManager.TICK_INTERVAL

		   # Smoothly interpolate the rotation
			var current_rotation = Vector3(
				start_rotation.x,
				rotate_toward(start_rotation.y, target_rotation.y, t * GameManager.ROTATE_SPEED),
				start_rotation.z
			)
			if (global_transform.origin != target):
				mesh.rotation = current_rotation
				
			# determine the terrain height to place the player accordingly
			if (terrain_cast.is_colliding()):
				target.y = terrain_cast.get_collision_point().y
			
			# Smoothly lerp the character to the target cell
			global_transform.origin = lerp(start_position, Vector3(target.x, target.y, target.z), t)
			
			await get_tree().create_timer(0.01).timeout
		
		global_transform.origin = target
		terrain_cast.enabled = false
	
func get_current_tile() -> Vector2:
	var grid_cell_v3 = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	return Vector2(grid_cell_v3.x, grid_cell_v3.z)
	
# triggered every game 'tick'
func _on_tick():
	# Process the move request during the tick (eventually, this should be done on the "server" side		
	if (len(movement_path) > 0):
		# move to next cell
		move_to_cell(movement_path.pop_front())
		
func _on_self_entity_updated(my_entity: Player):
	match my_entity.state:
		Constants.PLAYER_STATE.MOVING:
			process_movement(my_entity.target_cell)
