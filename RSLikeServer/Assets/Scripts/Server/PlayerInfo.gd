extends Node

const DEFAULT_COORDINATES = Vector2(0, 0)

class PlayerInfo:
	var current_cell: Vector2 # position
	var peer_id

	func _init(id):
		self.peer_id = id
		self.current_cell = DEFAULT_COORDINATES
		
func get_peer_ids(players):
	return players.map(func(player): return player.peer_id)

func prepare_for_rpc(players):
	var player_dict = {}
	
	for player in players:
		# TEMP (TESTING)
		var rng = RandomNumberGenerator.new()
		var x = rng.randi_range(-5, 5)
		var y = rng.randi_range(-5, 5)
		player.current_cell = Vector2(x, y)
		# TEMP
		player_dict[player.peer_id] = player.current_cell
		
	return player_dict
