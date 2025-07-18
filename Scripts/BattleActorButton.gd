# BattleActorButton.gd
extends TextureButton
class_name BattleActorButton

const RECOIL : int = 8
const HIT_TEXT : PackedScene = preload("res://Scenes/HitText.tscn")

signal attack_finished(target_button : BattleActorButton)

@export var actor_class : String = ""         # Must match a key in Data.class_configs

@onready var anim_sprite      : AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var start_pos        : Vector2          = position
@onready var recoil_direction : int              = 1 if global_position.x > Globals.GAME_SIZE.x * 0.5 else -1

# Runtime state
var actor        :BattleActor  = null
var data         :BattleActor  = null
var tween        :Tween        = null
var attack_anim  :String       = ""
var idle_anim    :String       = ""
var hurt_anim    :String       = ""

func _ready() -> void:
	pass

func set_data(_data : BattleActor) -> void:
	# 1) Assign the BattleActor resource
	data = _data

	# 2) Connect its signals
	data.hp_changed.connect(_on_data_hp_changed)
	data.defeated.connect(_on_data_is_defeated)
	data.acting.connect(_on_data_acting)

	# 3) If the resource carries its own texture override, use it
	if data.texture:
		texture_normal = data.texture

func _set_actor(value:BattleActor) -> void:
	actor = value
	set_data(actor)

func _on_pressed() -> void:
	# This is where you select your actual target. For demo:
	var target : BattleActorButton
	_attack(target)

func _attack(target_btn : BattleActorButton) -> void:
	#data.act()
	#await tween.finished
	if attack_anim != "" and anim_sprite:
		anim_sprite.play(attack_anim)
		await anim_sprite.animation_finished
		anim_sprite.play(idle_anim)
	else:
		print("Warning: attack animation '%s' not found!" % attack_anim)
	target_btn.data.healhurt(-data.strength)
	await get_tree().create_timer(0.5).timeout
	# Return to idle animation
	if idle_anim != "" and anim_sprite:
		anim_sprite.play(idle_anim)
	emit_signal("attack_finished", target_btn)

func play_hurt_animation():
	if hurt_anim != "" and anim_sprite:
		anim_sprite.play(hurt_anim)
		await anim_sprite.animation_finished
		if idle_anim != "" and anim_sprite:
			anim_sprite.play(idle_anim)
	else:
		print("Warning: hurt animation '%s' not found!" % hurt_anim)

func _on_data_acting() -> void:
	# Slide‐in tween when data.act() fires
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x",start_pos.x - (RECOIL * recoil_direction), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func _recoil() -> Tween:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x",start_pos.x + (RECOIL * recoil_direction), 0.25).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate",Color.RED, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate",Color.WHITE, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tween

func _action_slide() -> Tween:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction * -1), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	return tween

func _on_data_hp_changed(hp : int, change : int) -> void:
	var hit_text : Label = HIT_TEXT.instantiate()
	hit_text.text     = str(abs(change))
	add_child(hit_text)
	hit_text.position = Vector2(size.x * 0.5, -4)
	play_hurt_animation()

	if change < 0:
		_recoil()

func _on_data_is_defeated() -> void:
	# Grey‐out or remove, your choice
	self_modulate = Color.BLACK
