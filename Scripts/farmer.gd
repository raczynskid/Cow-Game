extends RigidBody3D

@export var WALK_SPEED : int = 2

var speed : float
var vel : Vector3
var state_machine
enum states {IDLE, WALKING, ATTACKING, MILKING, BUILDING}
var current_state = states.IDLE
var building_interaction_planned = null
var unit_interaction_planned = null
@onready var animation_tree = $AnimationTree
@onready var selection_ring = $Selection

var team : int = 0
@onready var progress_bar = $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine = animation_tree.get("parameters/playback")
	speed = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var target = $NavigationAgent3D.get_next_path_position()
	var pos = get_global_transform().origin
	
	var n = $RayCast3D.get_collision_normal()
	if n.length_squared() < 0.001:
		n = Vector3(0, 1, 0)
		
	vel = (target - pos).slide(n).normalized() * speed
	#$Armature.rotation.y = lerp_angle($Armature.rotation.y, atan2(vel.x, vel.z), delta * 10)
	
	$NavigationAgent3D.set_velocity(vel)

func select():
	selection_ring.show()
	
func deselect():
	selection_ring.hide()

func change_state(state):
	match state:
		"idle":
			current_state = states.IDLE
			speed = 0.000001
			state_machine.travel("Idle")
			if progress_bar.get_progress() == 0:
				progress_bar.visible = false
			$MilkTimer.stop()
		"walking":
			current_state = states.WALKING
			state_machine.travel("Walk")
			speed = WALK_SPEED
			if progress_bar.get_progress() == 0:
				progress_bar.visible = false
			$MilkTimer.stop()
		"milking":
			current_state = states.MILKING
			progress_bar.visible = true
			$MilkTimer.start()
			

func move_to(target_pos):
	change_state("walking")
	var closest_pos = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), target_pos)
	$NavigationAgent3D.set_target_position(closest_pos)

func _on_navigation_agent_3d_target_reached():
	if building_interaction_planned:
		building_interaction_planned.interact_with_unit(self)
	if unit_interaction_planned && !(unit_interaction_planned.is_in_group("farmer")):
		unit_interaction_planned.interact_with_unit(self)
		change_state("milking")
		
	else:
		change_state("idle")

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	set_linear_velocity(safe_velocity)


func _on_milk_timer_timeout():
	progress_bar.add_progress(1)
	
func interact_with_unit(unit):
	pass
