extends Sprite3D
@onready var unit_icons = $Node3D.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func increase_unit_count():
	for icon in unit_icons:
		if not icon.visible:
			icon.visible = true
			return

func decrease_unit_count():
	for i in range(unit_icons.size()-1, -1, -1):
		var icon = unit_icons[i]
		if icon.visible:
			icon.visible = false
			return
