extends Node3D

# Our global Refs
@export var __: Refs

# Reference to the terrain RayCast (used for determining terrain height)
@export var terrain_cast: RayCast3D

# Define the maximum wait time for terrain collision raycasting
const CAST_TIMEOUT = 1

func move_flag(target: Vector3):
	position = target
	visible = false
	terrain_cast.enabled = true # determine terrain height
	
	var elapsed_time = 0.0
	
	# determine the terrain height to place the flag accordingly
	while (!terrain_cast.is_colliding()):
		elapsed_time += get_process_delta_time()
		await get_tree().create_timer(.01).timeout
		if (elapsed_time >= CAST_TIMEOUT):
			terrain_cast.enabled = false
			return
	
	position.y = terrain_cast.get_collision_point().y

	visible = true
	terrain_cast.enabled = false
