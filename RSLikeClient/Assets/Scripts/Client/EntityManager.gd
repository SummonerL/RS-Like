extends Node

# Our global Refs
@export var __: Refs

# List of instantiated players
var instantiated_players: Array[PlayerEntityNode] = []

# List of non-player instantiated entities
# Cell -> Entity
var instantiated_entities: Dictionary = {} 

# Parent to all entities created on the client
@export var client_entities: Node

# Singal for indicating that the current player entity was updated by the server, thus requiring client changes
signal process_self(Player)

# Scenes for initializing various entities
var other_player_scene = load("res://Assets/Scenes/Entities/OtherPlayer.tscn")
var ash_tree_scene = load("res://Assets/Scenes/Entities/World/AshTree.tscn")

# Note: For each of these 'process_' functions, we are essentially analyzing the
# entities that the server sent to this client, to determine what to do with this information.
# Generally, the server sends these entities if it deems the peer to be 'interested' in this entity.
# By default, a player will generally be 'interested' in the entities that are in its physical vicinity.
# Note that the server will also usually send information to a client when there is a change in state in
# the entity.
func process_player(my_id, player_entity: Player):
	if (my_id == player_entity.peer_id): 
		emit_signal("process_self", player_entity)
		return
	
	# first, determine if this player is already instantiated in the active player's game world	
	var player_entity_node: PlayerEntityNode = null
	for instantiated_player in instantiated_players:
		if player_entity.peer_id == instantiated_player.player_entity.peer_id:
			player_entity_node = instantiated_player
	if (player_entity_node == null):
		# This player will now be instantiated. 
		# By default, the player is not 'visible' until the conditions are met to make them 
		# visible (generally through movement, or connecting to the server beside the active player)
		player_entity_node = add_instantiated_player(player_entity)
		player_entity_node.player_node.determine_and_set_visibility()
		
	# then, process the other player based on the state
	match player_entity.state:
		Constants.PLAYER_STATE.MOVING:
			player_entity_node.player_node.process_movement(player_entity.target_cell, player_entity.movement_grid)

func process_non_player_entity(entity):
	# first, determine if the player is already aware of the entity
	if (instantiated_entities.has(entity.current_cell)):
		return
	
	var instantiated_entity
	
	# otherwise, add and process the entity
	if entity is AshTree:
		instantiated_entity = ash_tree_scene.instantiate()
	
	instantiated_entities[entity.current_cell] = instantiated_entity # track this entity in the entity manager
	client_entities.add_child(instantiated_entity) # add node to scene tree
	instantiated_entity.teleport_to_cell(entity.current_cell, entity.height) # position the entity in the game world
	instantiated_entity.determine_and_set_visibility()

func add_instantiated_player(player_entity: Player) -> PlayerEntityNode:
		var player_node_instance = other_player_scene.instantiate()
		player_node_instance.set_peer_id(player_entity.peer_id)
		var new_player_entity = PlayerEntityNode.new(player_entity, player_node_instance)
		instantiated_players.append(new_player_entity);
		client_entities.add_child(player_node_instance)
		player_node_instance.teleport_to_cell(player_entity.current_cell) # position the player in the game world
		
		return new_player_entity

func remove_instantiated_player(peer_id):
	var player_to_remove: PlayerEntityNode = null
	var i = 0
	for instantiated_player in instantiated_players:
		if peer_id == instantiated_player.player_entity.peer_id:
			player_to_remove = instantiated_player
			break
		i += 1
	
	if (player_to_remove != null):
		instantiated_players.remove_at(i)
		client_entities.remove_child(player_to_remove.player_node)

func get_instantiated_players():
	return instantiated_players

# Given that all instantiated entities are invisible until certain conditions are met, this lets
# us scan through and determine visibility for all instantiated entities
func determine_and_set_visibility_all_entities() -> void:
	for player_entity_node in instantiated_players:
		player_entity_node.player_node.determine_and_set_visibility()

class PlayerEntityNode:
	var player_entity: Player
	var player_node
	
	func _init(entity, node):
		player_entity = entity
		player_node = node
