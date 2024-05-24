"""
	Script: GameSettings.gd
	Description: This script adds utilities pertaining to the GridMap that the game objects
	live on. An example utility is a function which converts the world position to a GridMap Cell coordinate.
"""
extends GridMap

# The cells on the grid that are occupied by a mesh
var used_grid_cells = [] # Vector3 Array
var used_grid_cells_2d = [] # Vector2 Array

func _ready():
	var used_source_cells = get_used_cells() # does not consider the mesh size

	# Determine and initialize cells occupied by a mesh
	for source_cell in used_source_cells:
		used_grid_cells.append_array(determine_mesh_cells(source_cell))
		
	used_grid_cells_2d = used_grid_cells.map(func(cell): return Vector2(cell.x, cell.z))

	# debugging 
	show_grid()
	
# used for debugging
func show_grid():
	var wireframe_material: StandardMaterial3D = StandardMaterial3D.new()
	wireframe_material.albedo_color = Color(1, 0, 0, 0.5)  # Red color with some transparency

	# all occupied cells on the grid (factoring in mesh size)
	for cell in used_grid_cells:
		draw_cell_box(cell, wireframe_material)

# determined the grid map cells that a given mesh (origin point) occupies
func determine_mesh_cells(mesh_origin_cell):
	var mesh_grid_cells = []
	
	# Get the item in the cell
	var item_index: int = get_cell_item(mesh_origin_cell)
	if item_index == GridMap.INVALID_CELL_ITEM:
		return []

	# Get the mesh size from the MeshLibrary (assuming all items have the same dimensions)
	var mesh: Mesh = mesh_library.get_item_mesh(item_index)
	var aabb: AABB = mesh.get_aabb()
	var mesh_size: Vector3 = aabb.size / cell_size  # Size in terms of grid cells
	mesh_size.y = 1 # Assume (basically) no height

	# Calculate the start position by offsetting for the center
	var start_offset: Vector3 = mesh_size * -0.5
	var start_cell: Vector3i = mesh_origin_cell + Vector3i(start_offset)
	
	# Iterate through all cells that the mesh occupies
	for x in range(int(mesh_size.x)):
		for y in range(int(mesh_size.y)):
			for z in range(int(mesh_size.z)):
				var offset = Vector3i(x, y, z)
				var cell_position = start_cell + offset
				mesh_grid_cells.append(cell_position)
				
	return mesh_grid_cells

func draw_cell_box(cell, wireframe_material):
	# draw box around all non-empty cells
	var cell_position: Vector3 = map_to_local(cell) + cell_size * 0.5  # Center the box
	
	# Create a new ImmediateMesh for the square
	var square_mesh: ImmediateMesh = ImmediateMesh.new()

	# Define the vertices of the square
	var half_size: Vector3 = cell_size * 0.5
	var vertices := [
		Vector3(-half_size.x, 0, -half_size.z),
		Vector3(half_size.x, 0, -half_size.z),
		Vector3(half_size.x, 0, half_size.z),
		Vector3(-half_size.x, 0, half_size.z)
	]

	# Draw the square using lines
	square_mesh.surface_begin(Mesh.PRIMITIVE_LINES, wireframe_material)
	for i in range(vertices.size()):
		square_mesh.surface_add_vertex(cell_position + vertices[i])
		square_mesh.surface_add_vertex(cell_position + vertices[(i + 1) % vertices.size()])
	square_mesh.surface_end()

	# Create a MeshInstance3D to display the ImmediateMesh
	var square_instance: MeshInstance3D = MeshInstance3D.new()
	square_instance.mesh = square_mesh

	# Add the square to the scene
	add_child(square_instance)
	
# finds the shortest path, using A*.
# Cnsiders occupied cells and diagonal movement
func find_path(start_cell, end_cell):
	var open_list = []
	var closed_list = []
	var start_node: GridNode = null
	var end_node: GridNode = null
	
	start_node = GridNode.new(start_cell)
	end_node = GridNode.new(end_cell)
	
	# the open list begins with the starting node
	open_list.append(start_node)
	
	while len(open_list) > 0:
		var current_node = open_list[0]
		var current_index = 0
		
		# Finds the lowest cost node in the open list
		for index in range(len(open_list)):
			if (open_list[index].f < current_node.f):
				current_node = open_list[index]
				current_index = index
			
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
			if (!used_grid_cells_2d.has(node_position)): # Ensure the cell is valid
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

# Used for A* pathfinding
class GridNode:
	var pos
	var g = 0 # Cost from the start node
	var h = 0 # Estimated cost to goal 
	var f = 0 # Total node cost
	var parent = null

	func _init(node_pos):
		self.pos = node_pos
