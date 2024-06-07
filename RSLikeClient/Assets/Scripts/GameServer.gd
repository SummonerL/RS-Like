extends Node

const DEV = true

var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9009

var connected_peer_ids = []

func _ready():
	if DEV == true:
		url = "127.0.0.1"
		
	connect_to_server()
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_server_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

@rpc
func sync_player_list(updated_connected_peer_ids):
	connected_peer_ids = updated_connected_peer_ids
	multiplayer_peer.get_unique_id()
	
	print("Currently connected Players: " + str(connected_peer_ids))


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
