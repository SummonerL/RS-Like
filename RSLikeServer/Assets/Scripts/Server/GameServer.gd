extends Node

const DEV = true

# Reference to the Refs object
@export var __: Node

# Server Information
var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9009
const MAX_CLIENTS = 4

# Connected players
var connected_players = [] # See PlayerInfo class

# Define the tick interval in seconds (600ms = 0.6 seconds)
const TICK_INTERVAL = .6

# A signal to notify other parts of the game that a tick has occurred
signal tick

# Timer for the tick system
var tick_timer

func _ready():
	if DEV == true:
		url = "127.0.0.1"
	var code = multiplayer_peer.create_server(PORT, MAX_CLIENTS)
	if (code != OK): return
	
	# Initialize the tick timer
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.one_shot = false
	tick_timer.connect("timeout", _on_tick)
	add_child(tick_timer)
	tick_timer.start()
	
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server is up and running.")


func _on_peer_connected(new_peer_id : int) -> void:
	print("Player " + str(new_peer_id) + " is joining...")
	# The connect signal fires before the client is added to the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout
	add_player(new_peer_id)


func add_player(new_peer_id : int) -> void:
	var new_player = __.player_info.PlayerInfo.new(new_peer_id)
	
	connected_players.append(new_player)
	print("Player " + str(new_peer_id) + " joined.")
	
	var connected_peer_ids = __.player_info.get_peer_ids(connected_players)
	print("Currently connected Players: " + str(connected_peer_ids))
	rpc("sync_player_list", connected_peer_ids)
	
	# set the new player position
	rpc_id(new_peer_id, "set_player_position", new_player.current_cell)


func _on_peer_disconnected(leaving_peer_id : int) -> void:
	# The disconnect signal fires before the client is removed from the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout 
	remove_player(leaving_peer_id)


func remove_player(leaving_peer_id : int) -> void:
	var i = 0
	for player in connected_players:
		if (player.peer_id == leaving_peer_id):
			connected_players.remove_at(i)
		i += 1
		
	print("Player " + str(leaving_peer_id) + " disconnected.")
	
	var connected_peer_ids = __.player_info.get_peer_ids(connected_players)
	rpc("sync_player_list", connected_peer_ids)

@rpc
func sync_player_list(_updated_connected_peer_ids):
	pass # only implemented in client (but still has to exist here)
	

@rpc
# accepts and holds player requests 
func new_player_request(target_cell):
	pass
	
@rpc
# sets the connected player position in the game world (client imp)
func set_player_position(target_cell):
	pass
	
# Function called on every tick
func _on_tick():
	emit_signal("tick")
	rpc("tick_client", __.player_info.prepare_for_rpc(connected_players))
	
@rpc
# invoked on the client every game tick (client imp)
func tick_client(player_dict):
	pass
