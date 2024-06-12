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
var connected_players: Array[Player] = [] # See Player class

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
	
	# Initialize the game tick timer
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.one_shot = false
	tick_timer.connect("timeout", _on_tick)
	add_child(tick_timer)
	tick_timer.start()
	
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("Server is up and running!")

# Peer connect / disconnect handlers
func _on_peer_connected(new_peer_id : int) -> void:
	print("Player " + str(new_peer_id) + " is joining...")
	# The connect signal fires before the client is added to the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout
	add_player(new_peer_id)

func _on_peer_disconnected(leaving_peer_id : int) -> void:
	# The disconnect signal fires before the client is removed from the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout 
	remove_player(leaving_peer_id)

# Initialize new player object and update interested peers
func add_player(new_peer_id : int) -> void:
	var new_player = Player.new()
	new_player.peer_id = new_peer_id
	
	connected_players.append(new_player)
	print("Player " + str(new_peer_id) + " joined.")
	
	var connected_peer_ids = connected_players.map(func(player): return player.peer_id)
	print("Currently connected Players: " + str(connected_peer_ids))

	# notify all peers of new player
	rpc("sync_player_list", connected_peer_ids) 
	
	# only send player entity details to interested peers
	send_entity_to_interested_peers(new_player)
	
	# set the new player position
	rpc_id(new_peer_id, "set_player_position", new_player.current_cell)

# Remove player object and update interested peers
func remove_player(leaving_peer_id : int) -> void:
	var i = 0
	for player in connected_players:
		if (player.peer_id == leaving_peer_id):
			connected_players.remove_at(i)
		i += 1
		
	print("Player " + str(leaving_peer_id) + " disconnected.")
	
	var connected_peer_ids = connected_players.map(func(player): return player.peer_id)
	rpc("sync_player_list", connected_peer_ids)
	
# An 'interested peer' is a connected peer that is interested in changes to a given entity.
# For example, a player who is close to an enemy would be 'interested' to know the enemies current
# coordinates and state. For reference, we refer to an 'entity' as an object with state. Generally
# these entities will actually be rendered in the game world. Examples include players, enemies, items
# that are on the ground, trees (chopped, unchopped), rocks (mined, not mined), doors (open, closed), etc.
# Examples of objects that are not considered entities are any objects that do not have state (walls,
# decorative objects, etc)
func determine_interested_peers(serializable_entity: SerializableEntity) -> Array:
	# for now, we will assume peers within a certain range of this object are interested
	var entity_pos = serializable_entity.current_cell
	var interested_peer_ids = []
	for peer: Player in connected_players:
		var distance = Utilities.get_distance(peer.current_cell, entity_pos)
		if distance <= Constants.MAX_INTERESTED: interested_peer_ids.append(peer.peer_id)
		
	return interested_peer_ids
	
func send_entity_to_interested_peers(serializable_entity) -> void:
	var interested_peer_ids = determine_interested_peers(serializable_entity)
	for peer_id in interested_peer_ids:
		rpc_id(peer_id, "send_entity", serializable_entity.to_dict()) 

# Function called on every tick
func _on_tick():
	emit_signal("tick")

@rpc
func send_entity(serialized_entity):
	pass


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


@rpc
# invoked on the client every game tick (client imp)
func tick_client(player_dict):
	pass
