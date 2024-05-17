extends Node

# Define the tick interval in seconds (600ms = 0.6 seconds)
const TICK_INTERVAL = 0.6

# A signal to notify other parts of the game that a tick has occurred
signal tick

# Timer for the tick system
var tick_timer

func _ready():
	# Initialize the tick timer
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.one_shot = false
	tick_timer.connect("timeout", _on_tick)
	add_child(tick_timer)
	tick_timer.start()

# Function called on every tick
func _on_tick():
	emit_signal("tick")
	# Add your game logic here
	# For example, process NPC movements, handle animations, etc.
