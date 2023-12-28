extends Sprite3D
@onready var progress_bar = $SubViewport/TextureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	texture = $SubViewport.get_texture()

func add_progress(amount):
	progress_bar.value += amount

func get_progress():
	return progress_bar.value

func reset():
	progress_bar.value = 0
