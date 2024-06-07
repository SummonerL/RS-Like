extends Node

var other_player_scene = load("res://Assets/Scenes/OtherPlayer.tscn")
var connected_players = {}

func instantiate_player(peer_id):
	var player_instance = other_player_scene.instantiate()
	
	connected_players[peer_id] = player_instance
	add_child(player_instance)
	
func remove_player(peer_id):
	remove_child(connected_players[peer_id])

func get_players():
	return connected_players
