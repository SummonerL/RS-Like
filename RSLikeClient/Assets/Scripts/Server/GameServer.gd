class_name GameServer extends Node

# Our global Refs
@export var __: Refs

const DEV = true

var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9009

var connected_player_ids: Array = []

func _ready():
	if DEV == true:
		url = "127.0.0.1"
		
	connect_to_server()
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_server_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# The main method of communication between server and client. Used to send serialized game entities
@rpc
func send_entity(serialized_entity):
	var my_id = multiplayer_peer.get_unique_id()
	var entity = SerializableEntity.from_dict(serialized_entity)

	# Determine entity type
	if entity is Player:
		__.entity_manager.process_player(my_id, entity as Player)

@rpc
# invoked on the client every game tick
func tick_client(player_dict):
	pass

@rpc
func sync_player_list(updated_connected_peer_ids):
	var my_id = multiplayer_peer.get_unique_id()
	
	# check for new players
	for id in updated_connected_peer_ids:
		if not connected_player_ids.has(id):
			connected_player_ids.append(id)
			
			print("New Player joined the server: " + str(id))
	
	# check for dropped players
	var i = 0
	for id in connected_player_ids:
		if not updated_connected_peer_ids.has(id):
			if (id == my_id): continue
			connected_player_ids.remove_at(i)
			__.entity_manager.remove_instantiated_player(id)
		i += 1
	
	print("Currently connected Players: " + str(connected_player_ids))

@rpc("any_peer")
# accepts and holds player requests (server imp)
func new_player_request(request: Dictionary):
	pass
	
# A signal to notify the player that the server is requesting a position update
signal update_player_position
@rpc
# sets the connected player position in the game world
func set_player_position(target_cell):
	emit_signal("update_player_position", target_cell)
	

# Server Connection / Disconnection 
func connect_to_server() -> void:
	print("Connecting to server...")
	multiplayer_peer.create_client(url, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	
func disconnect_from_server():
	multiplayer_peer.close()
	
	print("Disconnected from server.")

func _on_server_connected():
	print("Connected to server!")

func _on_server_connection_failed():
	multiplayer.multiplayer_peer = null
	print ("Connection to server failed...")

func _on_server_disconnected():
	multiplayer_peer.close()
	
	print("Connection to server lost...")
	
func send_player_request(type: Constants.REQUEST_TYPE, target_cell: Vector2):
	var request = {"Type": type, "Target": target_cell}
	rpc("new_player_request", request)
