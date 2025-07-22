class_name PlayerButton extends BattleActorButton

# Called when the button node is ready (added to scene)
func _ready():
	var idx = get_index()  # Get this button's index in the parent container
	var actor_instance: BattleActor = Data.party[idx]  # Get corresponding party member

	# If this actor has a valid class_key and is present in class_configs
	if actor_instance.class_key != "" and Data.class_configs.has(actor_instance.class_key):
		var class_cfg = Data.class_configs[actor_instance.class_key]
		attack_anim   = class_cfg.get("attack_anim", "")   # Set attack animation name
		idle_anim     = class_cfg.get("idle_anim", "")     # Set idle animation name
		hurt_anim     = class_cfg.get("hurt_anim", "")     # Set hurt animation name
		death_anim    = class_cfg.get("death_anim", "")    # Set death animation name
		skill1_anim   = class_cfg.get("skill1_anim", "")   # Set skill1 animation name
		var tex_path  = class_cfg.get("texture_path", "")  # Get the texture path
		if tex_path != "":
			texture_normal = load(tex_path)                 # Set static texture
		if anim_sprite:
			anim_sprite.frames = preload("res://Assets/Animations/Battle_Player.tres")
			if idle_anim != "" and anim_sprite:
				texture_normal = null                       # Use AnimatedSprite2D, hide static texture
				anim_sprite.show()
				anim_sprite.play(idle_anim)
			else:
				anim_sprite.hide()                        # Hide animation, use static texture
				texture_normal = load(tex_path)
	else:
		push_error("PlayerButton: Unknown or missing class_key for actor '%s'" % actor_instance.name)

	set_data(actor_instance)  # Attach the BattleActor data to this button

	# Make sure button's pressed signal is connected to its handler
	if not is_connected("pressed", Callable(self, "_on_pressed")):
		connect("pressed", Callable(self, "_on_pressed"))
