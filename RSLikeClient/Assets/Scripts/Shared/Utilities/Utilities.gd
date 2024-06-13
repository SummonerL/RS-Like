class_name Utilities

# Frequently used function which determines the distance (in cells) between two points.
static func get_distance(current_cell: Vector2, target_cell: Vector2):
	# chebyshev distance
	return max(abs(current_cell.x - target_cell.x), abs(current_cell.y - target_cell.y))

# Generally used for debugging purposes. The 'top_left' and 'bottom_right' can be anything, but reresent
# an area of potential cells
static func get_rand_cell(top_left: Vector2, bottom_right: Vector2):
	
	# Generate random x and y values within the specified range
	var random_x = randi_range(top_left.x, bottom_right.x)
	var random_y = randi_range(top_left.y, bottom_right.y)

	# Create a random Vector2 using the generated values
	return Vector2(random_x, random_y)
