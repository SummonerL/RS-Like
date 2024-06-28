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

# finds the shortest path, using A*.
# Cnsiders occupied cells and diagonal movement
static func find_path(start_cell, end_cell, map_data: MapDataInfo):
	var open_list = []
	var closed_list = []
	var start_node: GridNode = null
	var end_node: GridNode = null
	
	start_node = GridNode.new(start_cell)
	end_node = GridNode.new(end_cell)
	
	# Make sure that the target cell is actually reachable
	var map_data_cell_target
	if (map_data.cells.has(str(end_cell))):
		map_data_cell_target = map_data.cells[str(end_cell)]
	else: return
	if (map_data_cell_target.entity != null): # Ensure the cell is not blockable
		return []
	
	# the open list begins with the starting node
	open_list.append(start_node)
	
	while len(open_list) > 0:
		var current_node = open_list[0]
		
		# Finds the lowest cost node in the open list
		for index in range(len(open_list)):
			if (open_list[index].f < current_node.f):
				current_node = open_list[index]
			
		# We've evaluated the current node. Move it to the closed list
		open_list.erase(current_node)
		closed_list.append(current_node)
		
		# Determine and return the path by following node parent tree 
		if (current_node.pos == end_node.pos):
			var path = []
			var current = current_node
			while current != null:
				path.append(current.pos)
				current = current.parent
			path.reverse()
			path.pop_front() # We don't need the origin node
			return path
		
		# Determine Evaluate children (orthogonal and diagonal cells)
		var children = []
		for new_position in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]:
			var node_position = current_node.pos + new_position
			
			var map_data_cell
			if (map_data.cells.has(str(node_position))):
				map_data_cell = map_data.cells[str(node_position)]
			
			if (map_data_cell == null): # Ensure the cell is valid
				continue
				
			if (map_data_cell.entity != null): # Ensure the cell is not blockable
				continue
				
			# Here we can essentially "filter" the children based on the cell validity
			# This is where we can check for things like diagonal corner clipping or unwalkable
			# Cells.
				
			var new_node = GridNode.new(node_position)
			new_node.parent = current_node
			children.append(new_node)
			
		for child in children:
			var skip_child = false
			for closed_child in closed_list:
				if child.pos == closed_child.pos:
					skip_child = true # We have already evaluated this node
					break
					
			if (skip_child):
				continue
			
			child.g = current_node.g + 1
			child.h = (child.pos - end_node.pos).length()
			child.f = child.g + child.h
			
			for open_node in open_list:
				if (child.pos == open_node.pos and child.g > open_node.g):
					skip_child = true
					break
					
			if not (skip_child):
				open_list.append(child)
	return []

# useful function for converting strings to Vector2 (used primarily when pulling map data from file
static func string_to_vector2(string := "") -> Vector2:
	if string:
		var new_string: String = string
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array: Array = new_string.split(", ")

		return Vector2(int(array[0]), int(array[1]))

	return Vector2.ZERO

# Used for A* pathfinding
class GridNode:
	var pos
	var g = 0 # Cost from the start node
	var h = 0 # Estimated cost to goal 
	var f = 0 # Total node cost
	var parent = null

	func _init(node_pos):
		self.pos = node_pos
		
class MapDataInfo:
	var cells: Dictionary
		
class MapDataCell:
	var position: Vector2
	var height: float
	var entity: SerializableEntity
	
	func _init(position: Vector2, height: float):
		self.position = position
		self.height = height
