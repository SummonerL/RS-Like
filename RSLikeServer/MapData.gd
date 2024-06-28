class_name MapData extends Node

# Reference to the Refs object
@export var __: Refs

var map_data: Utilities.MapDataInfo

func _ready():
	# load map data into memory and initialize the game map
	var map_data_string = FileAccess.open("res://Assets/Data/map_data.json", FileAccess.READ)
	var map_data_dict: Dictionary = JSON.parse_string(map_data_string.get_as_text())
	
	map_data = Utilities.MapDataInfo.new()

	for cell_str in map_data_dict.keys():
		var cell = Utilities.string_to_vector2(cell_str)
		var cell_info = map_data_dict[cell_str]
		var map_data_cell = Utilities.MapDataCell.new(cell, cell_info.height)
		
		# populate entity, if any
		if (cell_info.has("entity")):
			map_data_cell.entity = create_entity(cell, Constants.ENTITY_TYPE[cell_info.entity], cell_info.height)
		
		map_data.cells[cell_str] = map_data_cell
		

func create_entity(position: Vector2, type: Constants.ENTITY_TYPE, height: float) -> SerializableEntity:
	var new_entity: SerializableEntity
	match type:
		Constants.ENTITY_TYPE.ASH_TREE:
			new_entity = AshTree.new()
			new_entity.set_position(position, height)
			# TODO: This is temporary, I don't think we should maintain a full list of entities like this
			__.game_server.all_entities[Constants.ENTITY_TYPE.ASH_TREE].append(new_entity)
	
	return new_entity
