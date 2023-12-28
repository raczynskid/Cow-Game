extends CharacterBody3D

const MOVE_MARGIN : int = 20
@export var MAX_UNITS_SELECTED = 100
@export var MOVE_SPEED : int = 15
@onready var cam : Camera3D = $Camera3D
@onready var selection_box : Node = $UnitSelector
@onready var navigation_mesh = $"../NavigationRegion3D"
@onready var barn_button = $"../CanvasLayer/GUIController/SelectionBarContainer/Button"

@export var units_in_circle : int = 4
@export var mouse_scroll : bool = false
@export var barn : PackedScene

var m_pos := Vector2()
var team : int = 0
const ray_length : int = 1000
var selected_units : Array = []
var old_selected_units : Array = []
var start_sel_pos = Vector2()
var target_positions_list : Array[Vector3] = []
var unit_pos_index : int = 0

var building_mode : bool = false
var building_under_construction


var fovStep = 0.1
@export var maxFov = 90.0
@export var minFov = 35.0

var x_rotation : float = -45
@export var max_vertical_tilt : float = 45
@export var min_vertical_tilt : float = -20

func _ready():
	pass # Replace with function body.

func _input(event):
	
	#mousewheel zoom
	if event.is_action_pressed("wheel_down"):
		cam.fov = lerp(cam.fov, maxFov, fovStep)
	if event.is_action_pressed("wheel_up"):
		cam.fov = lerp(cam.fov, minFov, fovStep)

	# mouse pivot
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * 0.01)
			var x_rotation_event = clamp(event.relative.y, -2, 2)
			x_rotation -= x_rotation_event
			x_rotation = clamp(x_rotation, -max_vertical_tilt, min_vertical_tilt)
			rotation_degrees.x = x_rotation

	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):

	m_pos = get_viewport().get_mouse_position()
	
	# process normal actions
	if not building_mode:
		if Input.is_action_just_pressed("command"):
			move_selected_units()
		if Input.is_action_just_pressed("select"):
			selection_box.start_pos = m_pos
			start_sel_pos = m_pos
		if Input.is_action_just_released("select"):
			select_units()
		if Input.is_action_pressed("select"):
			selection_box.m_pos = m_pos
			selection_box.is_visible = true
		else:
			selection_box.is_visible = false
			
	# process build mode actions
	else:
		if Input.is_action_just_pressed("select"):
			building_under_construction.build()
			disable_build_mode()
		else:
			if building_under_construction.under_cons:
				var intersect = raycast_from_mouse(0b100111)
				if intersect:
					var build_position = intersect.position
					building_under_construction.global_position = Vector3(build_position.x, 0, build_position.z)

	camera_movement()
	move_and_slide()

func camera_movement():
	
	# get keyboard input direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var viewport_size : Vector2 = get_viewport().size
	var origin : Vector3 = global_transform.origin
	
	# parse mouse input in relation to viewport
	# left
	if mouse_scroll:
		if origin.x > -62 and m_pos.x < MOVE_MARGIN:
			input_dir.x = -1

		# up
		if origin.z > -65 and m_pos.y < MOVE_MARGIN:
			input_dir.y = -1
		
		# right
		if origin.x < 62:
			if m_pos.x > viewport_size.x - MOVE_MARGIN:
				input_dir.x = 1
		
		# down
		if origin.z < 90:
			if m_pos.y > viewport_size.y - MOVE_MARGIN:
				input_dir.y = 1
	
	# transform velocity in relation to camera rotation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# translate direction to velocity
	if direction:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	# stop movement if no input
	else:
		velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVE_SPEED)
	
	return velocity

func raycast_from_mouse(collision_mask):
	var ray_start : Vector3 = cam.project_ray_origin(m_pos)
	var ray_end : Vector3 = ray_start + cam.project_ray_normal(m_pos) * ray_length
	var space_state = get_world_3d().direct_space_state
	var prqp := PhysicsRayQueryParameters3D.new()
	prqp.from = ray_start
	prqp.to = ray_end
	prqp.collision_mask = collision_mask
	prqp.exclude = []
	return space_state.intersect_ray(prqp)

func get_unit_under_mouse():
	var result_unit = raycast_from_mouse(0b110)
	if result_unit:
		var selected_unit = result_unit.collider
		return selected_unit

func select_units():
	var main_unit = get_unit_under_mouse()
	if selected_units.size() != 0:
		old_selected_units = selected_units
	selected_units = []
	if m_pos.distance_squared_to(start_sel_pos) < 16:
		if main_unit != null:
			selected_units.append(main_unit)
	else:
		selected_units = get_units_in_box(start_sel_pos, m_pos)
	
	if selected_units.size() != 0:
		clean_current_units_and_apply_new(selected_units)
	elif selected_units.size() == 0:
		deselect_all_units()

func deselect_all_units():
	for unit in get_tree().get_nodes_in_group("units"):
		unit.deselect()

func clean_current_units_and_apply_new(new_units):
	deselect_all_units()
	for unit in new_units:
		unit.select()

func move_selected_units():
	var result = raycast_from_mouse(0b100111)
	unit_pos_index = 0
	if selected_units.size() != 0:
		var first_unit = selected_units[0]
		if result.collider.is_in_group("surface"):
			for unit in selected_units:
				position_units(unit, result)

func get_units_in_box(top_left, bot_right):
	if top_left.x > bot_right.x:
		var tmp = top_left.x
		top_left.x = bot_right.x
		bot_right.x = tmp
	if top_left.y > bot_right.y:
		var tmp = top_left.y
		top_left.y = bot_right.y
		bot_right.y = tmp
		
	var box = Rect2(top_left, bot_right - top_left)
	var box_selected_units = []
	for unit in get_tree().get_nodes_in_group("units"):
		if box.has_point(cam.unproject_position(unit.global_transform.origin)):
			if box_selected_units.size() <= MAX_UNITS_SELECTED:
				box_selected_units.append(unit)
	return box_selected_units

func create_units_positions_in_a_circle(target_pos : Vector3, units_num : int):
	var possitions_list : Array[Vector3] = []
	var radius : float = 0.3
	var center = Vector2(target_pos.x, target_pos.z)
	var max_units_in_circle = units_in_circle
	var angle_step = PI * 2 / max_units_in_circle
	var angle = 0
	var unit_count = 0
	for i in range(0, units_num):
		if(unit_count == max_units_in_circle):
			radius += 0.3
			unit_count = 0
			angle = 0
			max_units_in_circle *= 2
			angle_step = 2 * PI / max_units_in_circle
		var direction = Vector2(cos(angle), sin(angle))
		var pos = center + direction * radius
		var pos_3d = Vector3(pos.x,0,pos.y)
		possitions_list.append(pos_3d)
		unit_count += 1
		angle += angle_step
	return possitions_list

func position_units(unit, result):
	target_positions_list = create_units_positions_in_a_circle(result.position, len(selected_units))
	unit.move_to(target_positions_list[unit_pos_index])
	unit_pos_index += 1

func _on_button_toggled(button_pressed):
	if button_pressed:
		enable_build_mode(barn)
	else:
		disable_build_mode()

func enable_build_mode(building):
	building_mode = true
	var new_building = building.instantiate()
	navigation_mesh.add_child(new_building)
	new_building.enable_construction_mode()
	building_under_construction = new_building

func disable_build_mode():
	building_under_construction = null
	navigation_mesh.bake_navigation_mesh()
	selection_box.start_pos = m_pos
	start_sel_pos = m_pos
	selection_box.is_visible = false
	building_mode = false
	barn_button.button_pressed = false
