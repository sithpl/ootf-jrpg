class_name BattleActorButton extends TextureButton

# Exports
@export var actor_class : String = ""         # Must match a key in Data.class_configs

# Onreadys
@onready var anim_sprite      : AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var start_pos        : Vector2          = position
@onready var recoil_direction : int              = 1 if global_position.x > Globals.GAME_SIZE.x * 0.5 else -1

# Signals
signal attack_finished(target_button : BattleActorButton)

# Constants
const RECOIL : int = 8
const HIT_TEXT : PackedScene = preload("res://Scenes/HitText.tscn")

# Variables
var actor        :BattleActor  = null
var data         :BattleActor  = null
var tween        :Tween        = null
var attack_anim  :String       = ""
var idle_anim    :String       = ""
var hurt_anim    :String       = ""
var death_anim   :String       = ""

func _ready() -> void:
	pass

func set_data(_data : BattleActor) -> void:
	#DEBUG print("BattleActorButton.gd/set_data() called")
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
	print("BattleActorButton.gd/_set_actor() called")
	actor = value
	set_data(actor)

func _on_pressed() -> void:
	print("BattleActorButton.gd/_on_pressed() called")
	# 1) Select a target
	var target : BattleActorButton
	# 2) Call attack() function
	_attack(target)

func _attack(target_btn : BattleActorButton) -> void:
	print("BattleActorButton.gd/_attack() called")
	# 1) Play attack animation & wait, then switch back to idle animation
	if attack_anim != "" and anim_sprite:
		anim_sprite.play(attack_anim)
		await anim_sprite.animation_finished
		anim_sprite.play(idle_anim)
	#else:
		## Output if attack_anim is null
		#print("Warning: attack animation '%s' not found!")
	# 2) Call healhurt() and apply damage to target
	target_btn.data.healhurt(-data.strength)
	# 3) Give healhurt() to resolve
	await get_tree().create_timer(0.5).timeout
	# 4) Return to idle animation
	if idle_anim != "" and anim_sprite:
		anim_sprite.play(idle_anim)
	# 5) Let em know that _attack() is done
	emit_signal("attack_finished", target_btn)

func _on_data_hp_changed(hp : int, change : int) -> void:
	print("BattleActorButton.gd/_on_data_hp_changed() called")
	var hit_text : Label = HIT_TEXT.instantiate()
	hit_text.text     = str(abs(change))
	add_child(hit_text)
	hit_text.position = Vector2(size.x * 0.5, -4)

	if change < 0:
		play_hurt_animation()
		_recoil()

func _recoil() -> Tween:
	print("BattleActorButton.gd/_recoil() called")
	# 1) If Tween is currently playing, stop it and void any set properties
	if tween:
		tween.kill()
	# 2) Create new Tween
	tween = create_tween()
	# 3) Push button backwards, flash red, move to original spot, make sure color is back to normal
	tween.tween_property(self, "position:x",start_pos.x + (RECOIL * recoil_direction), 0.25).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate",Color.RED, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", start_pos.x, 0.05).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate",Color.WHITE, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tween

func play_hurt_animation():
	print("BattleActorButton.gd/play_hurt_animation() called")
	if hurt_anim != "" and anim_sprite:
		# 1) Play hurt animation & wait
		anim_sprite.play(hurt_anim)
		await anim_sprite.animation_finished
		# 2) Switch back to idle animation
		if idle_anim != "" and anim_sprite:
			anim_sprite.play(idle_anim)
	#else:
		## Output if hurt_anim is null
		#print("Warning: hurt animation '%s' not found!" % hurt_anim)

func _on_data_is_defeated() -> void:
	print("BattleActorButton.gd/_on_data_is_defeated() called")
	play_death_animation()
	# Grey‐out or remove, your choice
	self_modulate = Color.BLACK

func play_death_animation():
	print("BattleActorButton.gd/play_death_animation() called")
	if death_anim != "" and anim_sprite:
		# 1) Play hurt animation & wait
		anim_sprite.play(hurt_anim)
		await anim_sprite.animation_finished
		# 2) Play death animation & wait
		anim_sprite.play(death_anim)
		await anim_sprite.animation_finished
		# 3) Set anim_sprite to death_anim, set to frame 3 (sprite on ground), declare animation is finished
		anim_sprite.set_animation(death_anim)
		anim_sprite.set_frame(3)
		anim_sprite.animation_finished
	#else:
		## Output if death_anim is null
		#print("Warning: death animation '%s' not found!" % death_anim)

func _on_data_acting() -> void:
	print("BattleActorButton.gd/_on_data_acting() called")
	# Slide‐in tween when data.act() fires
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x",start_pos.x - (RECOIL * recoil_direction), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func _action_slide() -> Tween: # TODO Maybe remove? Players have animations, enemies need to just flash and attack in place
	print("BattleActorButton.gd/_action_slide() called")
	# 1) If Tween is currently playing, stop it and void any set properties
	if tween: tween.kill()
	# 2) Create new Tween
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction * -1), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	return tween
