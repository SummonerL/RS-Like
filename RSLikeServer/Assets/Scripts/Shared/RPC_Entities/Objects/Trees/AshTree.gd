extends SerializableEntity

class_name AshTree

var state: Constants.TREE_STATE
var height: float # the terrain height at this cell (this is a static entity)

func _init(): # defaults
	self.state = Constants.TREE_STATE.UNCUT

func set_position(position: Vector2, height: float):
	self.current_cell = position
	self.target_cell = position
	self.height = height

func set_state(new_state: Constants.TREE_STATE):
	state = new_state
