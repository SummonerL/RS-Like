class_name Constants

# Default coordinates for most entities
static var DEFAULT_COORDINATES = Vector2(0, 0)

# The maximum distance of an entity from an 'interested' peer.
static var MAX_INTERESTED = 10;

enum PLAYER_STATE {IDLE, MOVING}
enum ENTITY_TYPE {PLAYER}

# Enumeration for different types of player requests
enum REQUEST_TYPE {
	MOVE,
	WOODCUT
}
