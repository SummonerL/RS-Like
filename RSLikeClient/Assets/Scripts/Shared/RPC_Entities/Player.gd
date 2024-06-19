extends SerializableEntity

class_name Player

var peer_id: int
var state: Constants.PLAYER_STATE
var movement_grid: Array

func _init(): # defaults
		self.current_cell = Utilities.get_rand_cell(Vector2(-5,-5), Vector2(5,5)) # Constants.DEFAULT_COORDINATES
		target_cell = current_cell
		self.state = Constants.PLAYER_STATE.IDLE

func set_state(new_state: Constants.PLAYER_STATE):
	state = new_state
	
# Because the server is the 'source of truth', we need to know and update the active cell
# Of this entity every tick, when is is moving.
func _move_by_tick(_caller: GameServer):
	current_cell = movement_grid.pop_front()
	
	if (current_cell == target_cell):
		movement_grid.clear()
		state = Constants.PLAYER_STATE.IDLE
		_caller.disconnect("tick", _move_by_tick)
