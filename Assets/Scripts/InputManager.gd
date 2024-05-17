"""
	Script: InputManager.gd
	Description:
"""
extends Node3D

func _process(delta):
	# this will be modified to depend on the current state
	if Input.is_action_pressed("camera_left"):
		rotation.y -= GameSettings.camera_speed * delta
