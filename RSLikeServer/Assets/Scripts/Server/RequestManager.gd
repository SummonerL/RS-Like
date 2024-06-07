extends Node

# Reference to the Refs object
@export var __: Node

# Enumeration for different types of player requests
enum RequestType {
	MOVE,
	WOODCUT
}

# List of all player requests currently awaiting processing
var player_requests = []

# Class to define a 'player request'. These will be queued up and processed every game tick.
class PlayerRequest:
	# Variables to store the type of request and associated data
	var request_type: RequestType
	var player_id: int
	var target_cell: Vector3
	
func _ready():
	# Connect to the tick signal
	__.game_server.connect("tick", _process_requests)
	
func _process_requests():
	pass
