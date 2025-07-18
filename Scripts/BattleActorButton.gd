# BattleActorButton.gd
extends TextureButton
class_name BattleActorButton

# Scene nodes & constants
const HIT_TEXT : PackedScene = preload("res://Scenes/HitText.tscn")
signal attack_finished(target_button : BattleActorButton)

const RECOIL : int = 8
@export var actor_class : String = ""         # Must match a key in Data.class_configs

@onready var anim_sprite      : AnimatedSprite2D = $AnimatedSprite2D
@onready var start_pos        : Vector2         = position
@onready var recoil_direction : int             = 1 if global_position.x > Globals.GAME_SIZE.x * 0.5 else -1

# Runtime state
var data        : BattleActor = null
var tween       : Tween        = null
var attack_anim : String       = ""


func _ready() -> void:
	# 1) Validate and fetch class config
	if actor_class == "":
		push_error("BattleActorButton: actor_class not set")
		return

	var class_cfg = Data.class_configs.get(actor_class)
	if typeof(class_cfg) != TYPE_DICTIONARY:
		push_error("BattleActorButton: Unknown class '%s'" % actor_class)
		return

	# 2) Pull in animation name & texture path
	attack_anim    = class_cfg.get("attack_anim", "")
	var tex_path   = class_cfg.get("texture_path", "")
	if tex_path != "":
		texture_normal = load(tex_path)

	# 3) Assign sprite sheet frames once
	if attack_anim != "" and anim_sprite:
		anim_sprite.frames = preload("res://Assets/Animations/Animations.tres")

	# 4) Wire up the click handler
	connect("pressed", Callable(self, "_on_pressed"))

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


func _on_pressed() -> void:
	# This is where you select your actual target. For demo:
	var target : BattleActorButton
	attack(target)


func attack(target_btn : BattleActorButton) -> void:
	# 1) Slide forward
	data.act()
	await tween.finished

	# 2) Play the sprite‐sheet attack animation
	if attack_anim != "":
		anim_sprite.play(attack_anim)
		await anim_sprite.animation_finished

	# 3) Deal damage
	target_btn.data.healhurt(-data.strength)

	## 4) Recoil back
	#_recoil()
	await get_tree().create_timer(0.5).timeout

	# 5) Notify battle manager
	emit_signal("attack_finished", target_btn)

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

func action_slide() -> Tween:
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

	if change < 0:
		_recoil()

func _on_data_is_defeated() -> void:
	# Grey‐out or remove, your choice
	self_modulate = Color.BLACK
