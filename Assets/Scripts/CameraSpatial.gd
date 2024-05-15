"""
	Script: CameraSpatial.gd
	Description: This script is attached to the Spatial parent of the player camera. This modifies
	the spacial in such a way that the child camera is moved appropriately.
"""
extends Node3D

const MIN_CAM_VERTICAL: int = 20
const MAX_CAM_VERTICAL: int = 70

# ensrure camera does not go above or below 'bounds'
func check_bounds():
	if (rotation_degrees.x < MIN_CAM_VERTICAL):
		rotation_degrees.x = MIN_CAM_VERTICAL
	
	if (rotation_degrees.x > MAX_CAM_VERTICAL):
		rotation_degrees.x = MAX_CAM_VERTICAL

func _process(delta):
	if Input.is_action_pressed("camera_left"):
		rotation.y -= GameSettings.camera_speed * delta
	if Input.is_action_pressed("camera_up"):
		rotation.x += GameSettings.camera_speed * delta
	if Input.is_action_pressed("camera_right"):
		rotation.y += GameSettings.camera_speed * delta
	if Input.is_action_pressed("camera_down"):
		rotation.x -= GameSettings.camera_speed * delta
		
	check_bounds()
