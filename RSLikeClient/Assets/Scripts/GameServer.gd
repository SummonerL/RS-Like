extends Node

# Our global Refs
@export var __: Node3D

const DEV = true

var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9009

var connected_peer_ids = []
var connected_players = {}

func _ready():
	if DEV == true:
		url = "127.0.0.1"
		
	connect_to_server()
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_server_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

@rpc
# invoked on the client every game tick
func tick_client(player_dict):
	pass

@rpc
func sync_player_list(updated_connected_peer_ids):
	connected_peer_ids = updated_connected_peer_ids
	var my_id = multiplayer_peer.get_unique_id()
	
	# check for new players
	for id in connected_peer_ids:
		if (id == my_id): continue
		if not connected_players.has(id):
			connected_players[id] = Vector2(0, 0)
			
			# instantiate the player
			__.instance_factory.instantiate_player(id)
	
	# check for dropped players
	for key in connected_players.keys():
		# Check if the key exists in the array of IDs
			if not connected_peer_ids.has(key):
				__.instance_factory.remove_player(key)
	
	print("Currently connected Players: " + str(connected_peer_ids))

@rpc
# accepts and holds player requests (server imp)
func new_player_request():
	pass
	
# A signal to notify the player that the server is requesting a position update
signal update_player_position
@rpc
# sets the connected player position in the game world
func set_player_position(target_cell):
	emit_signal("update_player_position", target_cell)

func connect_to_server() -> void:
	print("Connecting to server...")
	multiplayer_peer.create_client(url, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	
func _on_server_connected():
	print("Connected to server!")

func _on_server_connection_failed():
	multiplayer.multiplayer_peer = null
	print ("Connection to server failed...")
	
func disconnect_from_server():
	multiplayer_peer.close()
	
	print("Disconnected from server.")

func _on_server_disconnected():
	multiplayer_peer.close()
	
	print("Connection to server lost...")
