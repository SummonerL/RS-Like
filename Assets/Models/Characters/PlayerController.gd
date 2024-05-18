extends Node3D

# Variable to store the target position for the generic action request
var generic_request = null

# Reference to the world grid
@export var __: Node3D

func _ready():
	# Connect to the tick signal
	GameManager.connect("tick", _on_tick)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("left_click"):
		var target_position = get_viewport().get_mouse_position()
		generic_action_request(target_position)
		
# 'Generic', or default action, depending on the location or object clicked on.
# Note that we want to identify the target cell before the tick, so that the proper request is mad.e
func generic_action_request(target_position):
	
	# We need to raycast to determine the point on the GridMap where the user clicked. Naturally,
	# this depends on the camera.
	var from = __.camera.project_ray_origin(target_position)
	var to = from + __.camera.project_ray_normal(target_position) * 1000 # A far enough distance
	
	var space_state = __.camera.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	var result = space_state.intersect_ray(params)
	
	if result:
		var intersection_point = result.position
		# temp, try setting the click flag to this position
		__.click_flag.position = intersection_point
		__.click_flag.position.y = position.y
		
		var grid_x = int(intersection_point.x / __.world_grid.cell_size.x)
		var grid_y = int(intersection_point.y / __.world_grid.cell_size.y)
		var grid_z = int(intersection_point.z / __.world_grid.cell_size.z)
		generic_request = Vector3(grid_x, grid_y, grid_z)
	
func process_generic_request():
	print(generic_request)
	var target = __.world_grid.map_to_local(generic_request)
	target.x += (.5 * __.world_grid.cell_size.x)
	target.z += (.5 * __.world_grid.cell_size.z)
	position = target
	
# triggered every game 'tick'
func _on_tick():
	# Process the move request during the tick (eventually, this should be done on the "server" side
	if generic_request != null:
		process_generic_request()
		generic_request = null
