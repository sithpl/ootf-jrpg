class_name ScreenFlash extends ColorRect

@onready var _animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	self.modulate = Color(0, 0, 0, 1) # Start fully black
	play("RESET")

func play(anim: String):
	#DEBUG print("ScreenFlash.gd/play() called")
	_animation_player.play(anim)
	await _animation_player.animation_finished

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	#DEBUG print(_anim_name)
	#DEBUG print("ScreenFlash.gd/_on_AnimationPlayer_animation_finished() called")
	await get_tree().create_timer(0.7).timeout
	queue_free()
