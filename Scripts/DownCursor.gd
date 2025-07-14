class_name DownCursor extends Sprite2D

@onready var _anim: AnimationPlayer = $AnimationPlayer

func _ready():
	_anim.play("hover")
