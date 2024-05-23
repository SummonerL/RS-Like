extends Node3D

# Variable to store the target position for the generic action request
var generic_request = null

# Array to store the movement path for the player
var movement_path = [] # Vector2

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
		intersection_point.y = 0
		
		# temp, try setting the click flag to this position
		__.click_flag.position = intersection_point
		__.click_flag.position.y = position.y
		
		# convert intersection point to GridMap coordinate
		generic_request = __.world_grid.local_to_map(intersection_point)
	
func process_generic_request():
	# Assuming this is a walk request, determine and populate the walk path
	var source_cell = __.world_grid.local_to_map(Vector3(position.x, 0, position.z))
	
	movement_path = __.world_grid.find_path(Vector2(source_cell.x, source_cell.z), Vector2(generic_request.x, generic_request.z))
	
func move_to_cell(grid_cell):
	var target = __.world_grid.map_to_local(Vector3(grid_cell.x, 0, grid_cell.y))
	target.x += (.5 * __.world_grid.cell_size.x)
	target.z += (.5 * __.world_grid.cell_size.z)
	var move_c = move_coroutine(target)
	move_c.call()
	
func move_coroutine(target):
	return func() -> void:
		var elapsed_time = 0.0
		var start_position = global_transform.origin
		while elapsed_time < GameManager.TICK_INTERVAL:
			elapsed_time += get_process_delta_time()
			var t = elapsed_time / GameManager.TICK_INTERVAL
			global_transform.origin = lerp(start_position, Vector3(target.x, 0, target.z), t)
			await get_tree().create_timer(0.01).timeout
		global_transform.origin = target
	
# triggered every game 'tick'
func _on_tick():
	# Process the move request during the tick (eventually, this should be done on the "server" side
	if generic_request != null:
		process_generic_request()
		generic_request = null
		
	if (len(movement_path) > 0):
		# move to next cell
		move_to_cell(movement_path.pop_front())
