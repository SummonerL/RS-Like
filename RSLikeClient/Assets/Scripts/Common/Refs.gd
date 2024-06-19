"""
	Script: Refs.gd
	Description: This script is attached to an empty 'Ref' node. The purpose of this is to act as
	a reference to commonly accessed nodes (e.g grid, camera), to keep exports clean and 
	straightforward.
"""
class_name Refs extends Node

# Reference to the world grid
@export var world_grid: GridMap
@export var camera: Camera3D
@export var click_flag: Node3D
@export var game_server: GameServer
@export var entity_manager: Node
@export var main_player: Node3D
