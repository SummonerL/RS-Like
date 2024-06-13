class_name RequestManager extends Node

# Reference to the Refs object
@export var __: Refs

# List of all player requests currently awaiting processing
var player_requests: Array[PlayerRequest] = []

# signals that an entity has been updated due to some player request
signal entity_updated(SerializableEntity)

func _ready():
	# Connect to the tick signal
	# consider processing immediately, and sending the results on each tick, to avoid delays
	__.game_server.connect("tick", _process_requests)

# peer send a new action request to the server	
func new_request(type: Constants.REQUEST_TYPE, player: Player, target: Vector2):
	var request = PlayerRequest.new(type, player, target)
	player_requests.append(request)
	
# requests wil lbe processed as first-in first-out
func _process_requests():
	while player_requests.size() > 0:
		var request: PlayerRequest = player_requests.pop_front()
		
		match request.request_type:
			Constants.REQUEST_TYPE.MOVE:
				request.player.state = Constants.PLAYER_STATE.MOVING
				request.player.target_cell = request.target_cell
				emit_signal("entity_updated", request.player)
			_:
				pass
