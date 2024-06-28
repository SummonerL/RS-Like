extends Node3D

var __: Refs

# Clean this up. We want to attach the MeshInstance3D
var mesh: MeshInstance3D

func _ready():
	__ = get_parent().__
	
	for child in get_child(0).get_children():
		if child is MeshInstance3D:
			mesh = child

func teleport_to_cell(target_cell: Vector2, height: float):
	var absolute_position = get_parent().__.world_grid.map_to_local_center(target_cell)
	global_transform.origin = absolute_position
	
	# update y position to match the terrain
	global_transform.origin.y = height

func determine_and_set_visibility() -> void:
	visible = (Utilities.get_distance(__.main_player.get_current_tile(), get_current_tile()) <= Constants.MAX_INTERESTED)

func get_current_tile() -> Vector2:
	var grid_cell_v3 = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	return Vector2(grid_cell_v3.x, grid_cell_v3.z)
