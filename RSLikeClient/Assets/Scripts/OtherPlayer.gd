extends Node3D

# Reference to the terrain RayCast (used for determining terrain height)
@export var terrain_cast: RayCast3D

func teleport_to_cell(absolute_position): # clean this up
	global_transform.origin = absolute_position
