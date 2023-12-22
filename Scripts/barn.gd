extends Node3D

@onready var unit_destination = $UnitDestination

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
	unit_destination.position = $UnitSpawnPoint.position + Vector3(0.1,0,0.1)

func select():
	$Selection.visible = true

func deselect():
	$Selection.visible = false

func move_to(target_pos):
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
