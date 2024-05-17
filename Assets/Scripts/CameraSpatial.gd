"""
	Script: CameraSpatial.gd
	Description: This script is attached to the Spatial parent of the player camera. This modifies
	the spacial in such a way that the child camera is moved appropriately.
"""
extends Node3D

const MIN_CAM_VERTICAL: int = 20
const MAX_CAM_VERTICAL: int = 70

# Variable to store the target position for the generic action request
var generic_request = null

# Reference to the world grid
@export var world_grid: GridMap

func _ready():
	# Connect to the tick signal
	GameManager.connect("tick", _on_tick)

func _process(delta):
	# Client side input handling
	if Input.is_action_pressed("camera_left"):
		rotation.y -= GameSettings.camera_speed * delta
	if Input.is_action_pressed("camera_up"):
		rotation.x += GameSettings.camera_speed * delta
	if Input.is_action_pressed("camera_right"):
		rotation.y += GameSettings.camera_speed * delta
	if Input.is_action_pressed("camera_down"):
		rotation.x -= GameSettings.camera_speed * delta
		
	check_bounds()
	
	if Input.is_action_just_pressed("left_click"):
		var target_position = get_viewport().get_mouse_position()
		generic_action_request(target_position)

# triggered every game 'tick'
func _on_tick():
	# Process the move request during the tick (eventually, this should be done on the "server" side
	if generic_request != null:
		process_generic_request()
		generic_request = null

# ensure camera does not go above or below 'bounds'
func check_bounds():
	if (rotation_degrees.x < MIN_CAM_VERTICAL):
		rotation_degrees.x = MIN_CAM_VERTICAL
	
	if (rotation_degrees.x > MAX_CAM_VERTICAL):
		rotation_degrees.x = MAX_CAM_VERTICAL
		
# 'generic', or default action, depending on the location or object clicked on
func generic_action_request(target_position):
	generic_request = target_position
	
func process_generic_request():
	var map_coordinates = world_grid.to_map(generic_request)
	print(map_coordinates)
