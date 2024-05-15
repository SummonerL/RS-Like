"""
	Script: CameraSpatial.gd
	Description: This script is attached to the Spatial parent of the player camera. This modifies
	the spacial in such a way that the child camera is moved appropriately.
"""
extends Node3D

func _process(delta):
	rotation.y += GameSettings.cameraSpeed * delta
