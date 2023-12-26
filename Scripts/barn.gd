extends Node3D

@export var cow_scene: PackedScene

@onready var cow_spawn = $CowSpawnTimer
@onready var world = get_node("/root/World")

enum building_types {BARN, FEEDER}
var building_type

var spawning_unit
var spawning_img

var units_to_spawn = []
var under_cons = false

var cost : int = 200
var max_units : int = 4
var current_created_units : int = 0
var can_build = true



var progress_start = 10.0
var active = false
var is_rotating = false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("units")

func select():
	$Selection.visible = true

func deselect():
	$Selection.visible = false

func move_to(target_pos):
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn():
	var new_cow = cow_scene.instantiate()
	var spawn_destination = self.global_position
	spawn_destination.y += 0.2
	new_cow.global_position = spawn_destination
	var unit_destination = spawn_destination
	unit_destination.x -= 1
	world.add_child(new_cow)
	new_cow.move_to(unit_destination)

func _on_cow_spawn_timer_timeout():
	spawn()

func enable_construction_mode():
	under_cons = true
	
func build():
	under_cons = false
	
