extends Node3D

# Reference to the terrain RayCast (used for determining terrain height)
@export var terrain_cast: RayCast3D

var __: Refs

# client side rendering of another player's path
var movement_path = []

# Clean this up. We want to attach the MeshInstance3D
var mesh: MeshInstance3D

func _ready():
	__ = get_parent().__
	var test = get_tree().get_root()
	
	for child in get_child(0).get_children():
		if child is MeshInstance3D:
			mesh = child
	
	GameManager.connect("tick", _on_tick)

func teleport_to_cell(target_cell: Vector2):
	var absolute_position = get_parent().__.world_grid.map_to_local_center(target_cell)
	global_transform.origin = absolute_position
	
	snap_to_terrain()

# update the y position to match the terrain
func snap_to_terrain():
		terrain_cast.enabled = true # determine terrain height
		
		terrain_cast.force_raycast_update()
		if (terrain_cast.is_colliding()):
			global_transform.origin.y = terrain_cast.get_collision_point().y

		terrain_cast.enabled = false

func process_movement(target_cell: Vector2):
	
	var source_cell = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	
	# TODO: The server should ideally determine the movement path.
	movement_path = __.world_grid.find_path(Vector2(source_cell.x, source_cell.z), target_cell)
	
func move_to_cell(grid_cell):
	var target = __.world_grid.map_to_local_center(grid_cell)
	var move_c = move_coroutine(target)
	move_c.call()
	
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

# triggered every game 'tick'
func _on_tick():
	# Process the move request during the tick (eventually, this should be done on the "server" side		
	if (len(movement_path) > 0):
		# move to next cell
		move_to_cell(movement_path.pop_front())
