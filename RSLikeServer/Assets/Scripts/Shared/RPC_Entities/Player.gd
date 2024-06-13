extends SerializableEntity

class_name Player

var peer_id: int
var state: Constants.PLAYER_STATES

func _init(): # defaults
		self.current_cell = Utilities.get_rand_cell(Vector2(-5,-5), Vector2(5,5)) # Constants.DEFAULT_COORDINATES
		self.state = Constants.PLAYER_STATES.IDLE
