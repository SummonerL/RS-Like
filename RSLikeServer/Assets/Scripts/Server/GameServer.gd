class_name GameServer extends Node

const DEV = true

# Reference to the Refs object
@export var __: Refs

# Server Information
var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9009
const MAX_CLIENTS = 4

# All instantiated entities
var all_entities = {
	Constants.ENTITY_TYPE.PLAYER: [] # connected players
}

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
	
	__.request_manager.entity_updated.connect(_on_entity_updated)
	
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
	
	all_entities[Constants.ENTITY_TYPE.PLAYER].append(new_player)
	print("Player " + str(new_peer_id) + " joined.")
	
	var connected_peer_ids = all_entities[Constants.ENTITY_TYPE.PLAYER].map(func(player): return player.peer_id)
	print("Currently connected Players: " + str(connected_peer_ids))

	# notify all peers of new player
	rpc("sync_player_list", connected_peer_ids) 
	
	# only send player entity details to interested peers
	send_entity_to_interested_peers(new_player)
	
	# send the entities relevant to the new player
	for entity in determine_relevant_entities(new_player):
		rpc_id(new_peer_id, "send_entity", entity.to_dict())
	
	# set the new player position
	rpc_id(new_peer_id, "set_player_position", new_player.current_cell)

# Remove player object and update interested peers
func remove_player(leaving_peer_id : int) -> void:
	var i = 0
	for player in all_entities[Constants.ENTITY_TYPE.PLAYER]:
		if (player.peer_id == leaving_peer_id):
			all_entities[Constants.ENTITY_TYPE.PLAYER].remove_at(i)
		i += 1
		
	print("Player " + str(leaving_peer_id) + " disconnected.")
	
	var connected_peer_ids = all_entities[Constants.ENTITY_TYPE.PLAYER].map(func(player): return player.peer_id)
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
	var target_pos = serializable_entity.target_cell
	var interested_peer_ids = []
	for peer: Player in all_entities[Constants.ENTITY_TYPE.PLAYER]:
		var current_distance = Utilities.get_distance(peer.current_cell, entity_pos)
		var target_distance = Utilities.get_distance(peer.current_cell, target_pos)
		if (current_distance <= Constants.MAX_INTERESTED or target_distance <= Constants.MAX_INTERESTED): 
			interested_peer_ids.append(peer.peer_id)
		
	return interested_peer_ids
	
func send_entity_to_interested_peers(serializable_entity) -> void:
	var interested_peer_ids = determine_interested_peers(serializable_entity)
	for peer_id in interested_peer_ids:
		rpc_id(peer_id, "send_entity", serializable_entity.to_dict()) 

# From the full list of entities, determine which entities are relevant to the player
func determine_relevant_entities(peer: Player) -> Array[SerializableEntity]:
	var relevant_entities: Array[SerializableEntity] = []
	for entity_type in all_entities.keys():
		for entity: SerializableEntity in all_entities[entity_type]:
			var current_distance = Utilities.get_distance(peer.current_cell, entity.current_cell)
			var target_distance = Utilities.get_distance(peer.current_cell, entity.target_cell)
			if (current_distance <= Constants.MAX_INTERESTED or target_distance <= Constants.MAX_INTERESTED): 
				relevant_entities.append(entity)

	return relevant_entities

# generally called whenever the RequestManager updated an entity, which we will need to send back to interested peers
func _on_entity_updated(entity: SerializableEntity):
	send_entity_to_interested_peers(entity)

# Function called on every tick
func _on_tick():
	emit_signal("tick", self)

@rpc
func send_entity(serialized_entity):
	pass


@rpc
func sync_player_list(_updated_connected_peer_ids):
	pass # only implemented in client (but still has to exist here)
	

@rpc("any_peer") # signifies all peers can execute this proc
# accepts and holds player requests 
func new_player_request(request: Dictionary):
	var peer_id = multiplayer.get_remote_sender_id()
	var player = all_entities[Constants.ENTITY_TYPE.PLAYER].filter(func(player): return player.peer_id == peer_id)[0]
	__.request_manager.new_request(request["Type"], player, request["Target"])


@rpc
# sets the connected player position in the game world (client imp)
func set_player_position(target_cell):
	pass


@rpc
# invoked on the client every game tick (client imp)
func tick_client(player_dict):
	pass
