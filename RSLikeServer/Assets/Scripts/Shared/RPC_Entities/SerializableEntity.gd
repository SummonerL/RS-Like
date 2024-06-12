"""
	Script: SerializableEntity.gd
	Description: This is a class that server entities will extend that allows them to be serialized
	for RPC calls. Godot does not serialize complex objects over RPC, hence the need for something like this.
	As a general principle, we will try to reduce the amount of information sent to peers. To do this,
	we will try to send only the information that is relevant for a given peer. For example, a player would
	only need information about the entities within it's general radius (roughly the camera draw distance).
	And unless the state of this entity changes, we do not need to keep sending information to the peer.
	
	Note: This script was pretty much copied as-is from here:
	https://www.reddit.com/r/godot/comments/170r2pb/serializingdeserializing_custom_objects_fromto/
"""
class_name SerializableEntity

# TODO: Determine if there would be any non-positionable entities.
var current_cell: Vector2 # position of this entity in the world

# Convert instance to a dictionary.
func to_dict() -> Dictionary:
	var result = {
		"_type": get_script().get_path(),  # This is a reference to the class/script type.
	}
	
	for property in self.get_property_list():
		#print("Property name: ", property.name, " Usage: ", property.usage)
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[property.name] = get(property.name)
	
	return result


# Populate the instance from a dictionary.
static func from_dict(data: Dictionary) -> SerializableEntity:
	var instance = load(data["_type"]).new()
	
	for key in data.keys():
		if key != "_type":
			instance.set(key, data[key])
	
	return instance
