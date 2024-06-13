extends SerializableEntity

class_name Player

var peer_id: int
var state: Constants.PLAYER_STATE
var target_cell: Vector2 # used for action requests, should be the same as current_cell when IDLE

func _init(): # defaults
		self.current_cell = Utilities.get_rand_cell(Vector2(-5,-5), Vector2(5,5)) # Constants.DEFAULT_COORDINATES
		target_cell = current_cell
		self.state = Constants.PLAYER_STATE.IDLE
