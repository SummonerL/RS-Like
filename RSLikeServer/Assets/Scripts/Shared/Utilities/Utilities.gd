class_name Utilities

# Frequently used function which determines the distance (in cells) between two points.
static func get_distance(current_cell: Vector2, target_cell: Vector2):
	# chebyshev distance
	return max(abs(current_cell.x - target_cell.x), abs(current_cell.y - target_cell.y))
