class_name BattleActorButton extends TextureButton

# Signals
signal attack_finished(target_button : BattleActorButton)     # Notify when attack call is completed

# Exports
@export var actor_class        :String           = ""         # Must match a key in Data.class_configs

# Onreadys
@onready var anim_sprite       :AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var start_pos         :Vector2          = position
@onready var recoil_direction  :int              = 1 if global_position.x > Globals.GAME_SIZE.x * 0.5 else -1

# Constants
const RECOIL                   :int          = 8
const HIT_TEXT                 :PackedScene  = preload("res://Battle/HitText.tscn")

# Variables
var actor                      :BattleActor  = null           # The BattleActor this button represents (can be player or enemy)
var data                       :BattleActor  = null           # Alias for actor (used in signal connections)
var tween                      :Tween        = null           # Active Tween for animations
var attack_anim                :String       = ""             # Name of attack animation
var idle_anim                  :String       = ""             # Name of idle animation
var hurt_anim                  :String       = ""             # Name of hurt animation
var death_anim                 :String       = ""             # Name of death animation
var skill1_anim                 :String       = ""            # Name of skill1 animation

func _ready() -> void:
	pass

# Associate a BattleActor with this button and connect its signals
func set_data(_data : BattleActor) -> void:
	#DEBUG print("BattleActorButton.gd/set_data() called")
	# 1) Assign the BattleActor resource
	data = _data
	# 2) Connect its signals for health, defeat, and acting
	data.hp_changed.connect(_on_data_hp_changed)
	data.defeated.connect(_on_data_is_defeated)
	data.acting.connect(_on_data_acting)
	# 3) Use the actor's texture if available
	if data.texture:
		texture_normal = data.texture

# Set the BattleActor reference (for player buttons)
func _set_actor(value:BattleActor) -> void:
	#DEBUG print("BattleActorButton.gd/_set_actor() called")
	actor = value
	set_data(actor)

# Called when this button is pressed (if not overridden by child)
func _on_pressed() -> void:
	#DEBUG print("BattleActorButton.gd/_on_pressed() called")
	# 1) Select a target (logic not implemented here)
	var target : BattleActorButton
	# 2) Call attack (not used in current battle flow)
	_attack(target)

# Primary attack logic: plays animation, applies damage, emits signal when done
func _attack(target_btn : BattleActorButton) -> void:
	#DEBUG print("BattleActorButton.gd/_attack() called")
	# 1) Play attack animation & wait, then switch back to idle animation
	if attack_anim != "" and anim_sprite:
		anim_sprite.play(attack_anim)
		await anim_sprite.animation_finished
		anim_sprite.play(idle_anim)
	#else:
		## Output if attack_anim is null
		#print("Warning: attack animation '%s' not found!")
	# 2) Apply damage to target BattleActor
	target_btn.data.healhurt(-data.attack)
	# 3) Wait for hit text animation
	await get_tree().create_timer(0.5).timeout
	# 4) Return to idle animation
	if idle_anim != "" and anim_sprite:
		anim_sprite.play(idle_anim)
	# 5) Signal that attack is finished
	emit_signal("attack_finished", target_btn)

# Responds to BattleActor hp_changed signal: plays hurt/recoil, then shows hit text
func _on_data_hp_changed(_hp : int, change : int) -> void:
	#DEBUG print("BattleActorButton.gd/_on_data_hp_changed() called")
	if change < 0:
		play_hurt_animation()
		_recoil()  # Ensure recoil finishes before showing hit text
	
	await get_tree().create_timer(0.5).timeout

	# Show hit text after recoil
	var hit_text : Label = HIT_TEXT.instantiate()
	hit_text.z_index  = 100  # Ensure it's above enemy sprites
	hit_text.text     = str(abs(data.last_attempted_damage))  # Show attempted damage, not HP change
	# Center the text above the button
	hit_text.position = Vector2(self.size.x * 0.5 - hit_text.size.x * 0.5, -hit_text.size.y - 8)
	add_child(hit_text)

# Animates a quick physical recoil when damaged
func _recoil() -> Tween:
	#DEBUG print("BattleActorButton.gd/_recoil() called")
	# 1) Kill any current tween
	if tween:
		tween.kill()
	# 2) Create new Tween for position and color
	tween = create_tween()
	tween.tween_property(self, "position:x",start_pos.x + (RECOIL * recoil_direction), 0.25).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	#tween.parallel().tween_property(self, "self_modulate",Color.RED, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", start_pos.x, 0.05).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	#tween.parallel().tween_property(self, "self_modulate",Color.WHITE, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tween

# Play hurt animation when damaged
func play_hurt_animation():
	#DEBUG print("BattleActorButton.gd/play_hurt_animation() called")
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

# Responds to BattleActor defeated signal: plays death animation, greys out button
func _on_data_is_defeated() -> void:
	#DEBUG print("BattleActorButton.gd/_on_data_is_defeated() called")
	play_death_animation()
	# Grey‐out or remove, your choice
	self_modulate = Color.BLACK

# Play death animation
func play_death_animation():
	#DEBUG print("BattleActorButton.gd/play_death_animation() called")
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

# Responds to BattleActor acting signal: slide animation for attack/turn start
func _on_data_acting() -> void:
	#DEBUG print("BattleActorButton.gd/_on_data_acting() called")
	# Slide‐in tween when data.act() fires
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x",start_pos.x - (RECOIL * recoil_direction), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

# Unused: old animation to slide forward when attacking
# TODO Maybe remove? Players have animations, enemies need to just flash and attack in place
func _action_slide() -> Tween: 
	#DEBUG print("BattleActorButton.gd/_action_slide() called")
	# 1) If Tween is currently playing, stop it and void any set properties
	if tween: tween.kill()
	# 2) Create new Tween for alternate slide
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction * -1), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	return tween
