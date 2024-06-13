extends Node3D

# Reference to the terrain RayCast (used for determining terrain height)
@export var terrain_cast: RayCast3D

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
