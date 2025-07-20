class_name ScreenFlash extends ColorRect

@onready var _animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	play("RESET")

func play(anim: String):
	print("ScreenFlash.gd/play() called")
	_animation_player.play(anim)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	print(_anim_name)
	print("ScreenFlash.gd/_on_AnimationPlayer_animation_finished() called")
	queue_free()
