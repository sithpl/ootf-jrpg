class_name BattleActorButton extends TextureButton

const HIT_TEXT: PackedScene = preload("res://Scenes/HitText.tscn")

const RECOIL: int = 8

var data: BattleActor = null
var tween: Tween = null

@onready var start_pos: Vector2 = position
@onready var recoil_direction: int = 1 if global_position.x > Globals.GAME_SIZE.x * 0.5 else -1

func set_data(_data: BattleActor):
	data = _data
	
	if data.texture:
		texture_normal = data.texture # TODO might need to duplicate
	
	data.hp_changed.connect(_on_data_hp_changed)
	data.defeated.connect(_on_data_is_defeated)
	data.acting.connect(_on_data_acting)

func recoil():
	if tween:
		tween.kill()
	tween = create_tween()
	# Start
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction), 0.25).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", Color.RED, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# End
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func action_slide():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction * -1), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func _on_data_hp_changed(hp: int, change: int):
	var hit_text: Label = HIT_TEXT.instantiate()
	hit_text.text = str(abs(change))
	add_child(hit_text)
	hit_text.position = Vector2(size.x * 0.5, -4)
	
	if sign(change) == -1:
		recoil()

func _on_data_is_defeated():
	pass

func _on_data_acting():
	action_slide()
