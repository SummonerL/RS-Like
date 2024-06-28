extends Node3D

# Reference to the terrain RayCast (used for determining terrain height)
@export var terrain_cast: RayCast3D

var __: Refs

# client side rendering of another player's path
var movement_path = []

# Clean this up. We want to attach the MeshInstance3D
var mesh: MeshInstance3D

# keep a reference to our peer_id, which always comes in handy
var peer_id

func _ready():
	__ = get_parent().__
	
	for child in get_child(0).get_children():
		if child is MeshInstance3D:
			mesh = child
	
	GameManager.connect("tick", _on_tick)


func set_peer_id(id):
	peer_id = id

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

func process_movement(target_cell: Vector2, movement_path):
	var source_cell = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	self.movement_path = movement_path
	
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
		var target_terrain_height = start_position.y
		target.y = start_position.y

		while elapsed_time < GameManager.TICK_INTERVAL:
			elapsed_time += get_process_delta_time()
			var t = elapsed_time / GameManager.TICK_INTERVAL

			# set the terrain cast to the target cell
			terrain_cast.global_position = target
			terrain_cast.global_position.y += 5

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
				target_terrain_height = terrain_cast.get_collision_point().y
			
			# Smoothly lerp the character to the target cell + height
			var new_position = lerp(start_position, target, t)
			new_position.y = lerp(start_position.y, target_terrain_height, t)
			
			global_transform.origin = new_position
			
			await get_tree().create_timer(0.01).timeout
		
		global_transform.origin = Vector3(target.x, target_terrain_height, target.z)
		
		if (movement_path.size() == 0):
			terrain_cast.enabled = false

func determine_and_set_visibility() -> void:
	visible = (Utilities.get_distance(__.main_player.get_current_tile(), get_current_tile()) <= Constants.MAX_INTERESTED)

func get_current_tile() -> Vector2:
	var grid_cell_v3 = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	return Vector2(grid_cell_v3.x, grid_cell_v3.z)

# triggered every game 'tick'
func _on_tick():
	# Process the move request during the tick (eventually, this should be done on the "server" side)
	if (len(movement_path) > 0):
		# move to next cell
		var target_cell = movement_path.pop_front()
		
		# Because the player gets instantiated based on the 'final' position, we want to simply
		# toggle visibility if they are inside / outside of the active player's interest zone.
		# However, if the player ends its movement outside of the interest zone, we want to remove it entirely.
		# The reason for doing this is because movement, by default, is one cell per tick. So, if a player starts
		# several squares outside of the active player's interest zone, the server can still deem the active player 
		# to be interested, if this player will end their movement inside the zone. If we deleted the node every time
		# they entered a cell outside of the interest zone, we would run into a bug where, as they are potentially moving towards the
		# zone, they get deleted anyway, because they haven't made it inside the zone yet. This logic offers us more flexibility.
		if (Utilities.get_distance(__.main_player.get_current_tile(), target_cell) > Constants.MAX_INTERESTED):
			visible = false
			
			# the main player is no longer interested in me at all :(
			if (movement_path.size() == 0): # the final cell in player's movement path
				__.entity_manager.remove_instantiated_player(peer_id)
				queue_free()
				return
		else:
		# if the player is moving into the active's player's interest zone, we should make sure they
		# are visible (the node is invisible by default)
			if (!visible): visible = true

		move_to_cell(target_cell)
