# Class to define a 'player request'. These will be queued up and processed every game tick.
class_name PlayerRequest

# Variables to store the type of request and associated data
var request_type: Constants.REQUEST_TYPE
var player: Player
var target_cell: Vector2

func _init(type: Constants.REQUEST_TYPE, requester: Player, target: Vector2):
	request_type = type
	player = requester
	target_cell = target
