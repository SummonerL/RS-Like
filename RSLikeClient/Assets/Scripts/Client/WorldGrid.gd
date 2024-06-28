"""
	Script: GameSettings.gd
	Description: This script adds utilities pertaining to the GridMap that the game objects
	live on. An example utility is a function which converts the world position to a GridMap Cell coordinate.
"""
extends GridMap

# The cells on the grid that are occupied by a mesh
var used_grid_cells = [] # Vector3 Array
var used_grid_cells_2d = [] # Vector2 Array

@export var grid_terrain_ray: RayCast3D
var grid_rendered = false

func _ready():
	var used_source_cells = get_used_cells() # does not consider the mesh size

	# Determine and initialize cells occupied by a mesh
	for source_cell in used_source_cells:
		used_grid_cells.append_array(determine_mesh_cells(source_cell))
		
	used_grid_cells_2d = used_grid_cells.map(func(cell): return Vector2(cell.x, cell.z))

	# debugging 
	# show_grid()
	# save_to_file()
	
# used for debugging
func show_grid():
	await get_tree().create_timer(.01).timeout
	var wireframe_material: StandardMaterial3D = StandardMaterial3D.new()
	wireframe_material.albedo_color = Color(1, 0, 0, 0.5)  # Red color with some transparency

	# all occupied cells on the grid (factoring in mesh size)
	for cell in used_grid_cells:
		draw_cell_box(cell, wireframe_material)

# this is a 'tool' for saving the map data to an external file
func save_to_file():
	await get_tree().create_timer(.01).timeout
	var map_data = {}
	grid_terrain_ray.enabled = true
	for cell: Vector2 in used_grid_cells_2d:
		# get the height at the center of this cell
		var cell_position: Vector3 = map_to_local(Vector3(cell.x, 0, cell.y)) + cell_size * 0.5  # center position
		var height = 0

		grid_terrain_ray.position = Vector3(cell_position.x, 10, cell_position.z)
		grid_terrain_ray.force_raycast_update()
		if (grid_terrain_ray.is_colliding()):
			height = grid_terrain_ray.get_collision_point().y
		
		map_data[str(cell)] = { height = snappedf(height, 0.0001) }
		
		# Introduce randomness to simulate natural tree clustering
		if ((height < 4 and height > 1) and (randf() < 0.025)):
			map_data[str(cell)]["entity"] = "ASH_TREE"
		
	grid_terrain_ray.enabled = false
	
	var file_data = JSON.stringify(map_data)
	var file = FileAccess.open("user://map.json", FileAccess.WRITE)
	file.store_line(file_data)
	

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

# a useful extension of map_to_local that returns the center of the cell
func map_to_local_center(cell: Vector2):
	var target = map_to_local(Vector3(cell.x, 0, cell.y))
	target.x += (.5 * cell_size.x)
	target.z += (.5 * cell_size.z)
	return target

func draw_cell_box(cell, wireframe_material):
	# draw box around all non-empty cells
	var cell_position: Vector3 = map_to_local(cell) + cell_size * 0.5  # Center the box
	
	# Create a new ImmediateMesh for the square
	var square_mesh: ImmediateMesh = ImmediateMesh.new()

	# Define the vertices of the square
	var half_size: Vector3 = cell_size * 0.5
	
	var vertices := [
		Vector3(cell_position.x + -half_size.x, 0, cell_position.z + -half_size.z),
		Vector3(cell_position.x + half_size.x, 0, cell_position.z + -half_size.z),
		Vector3(cell_position.x + half_size.x, 0, cell_position.z + half_size.z),
		Vector3(cell_position.x + -half_size.x, 0, cell_position.z + half_size.z)
	]
	
	grid_terrain_ray.enabled = true
	
	# determine the height of the vertices, based on the terrain	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		grid_terrain_ray.position = Vector3(vertex.x, 10, vertex.z)
		grid_terrain_ray.force_raycast_update()
		if (grid_terrain_ray.is_colliding()):
			vertex.y = grid_terrain_ray.get_collision_point().y
		vertices[i] = vertex
		
	grid_terrain_ray.enabled = false
		
	# Draw the square using lines
	square_mesh.surface_begin(Mesh.PRIMITIVE_LINES, wireframe_material)
	for i in range(vertices.size()):
		square_mesh.surface_add_vertex(vertices[i])
		square_mesh.surface_add_vertex(vertices[(i + 1) % vertices.size()])
	square_mesh.surface_end()

	# Create a MeshInstance3D to display the ImmediateMesh
	var square_instance: MeshInstance3D = MeshInstance3D.new()
	square_instance.mesh = square_mesh

	# Add the square to the scene
	add_child(square_instance)
	
# returns the distance (in cells) between two points.
func get_distance(current_cell, target_cell):
	var current_2d = Vector2(current_cell.x, current_cell.z)
	var target_2d = Vector2(target_cell.x, target_cell.z)
	
	# chebyshev distance
	return max(abs(current_2d.x - target_2d.x), abs(current_2d.y - target_2d.y))
