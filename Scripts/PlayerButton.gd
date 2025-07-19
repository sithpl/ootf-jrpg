class_name PlayerButton extends BattleActorButton

func _ready():
	var idx = get_index()
	var actor_instance: BattleActor = Data.party[idx]

	if actor_instance.class_key != "" and Data.class_configs.has(actor_instance.class_key):
		var class_cfg = Data.class_configs[actor_instance.class_key]
		attack_anim = class_cfg.get("attack_anim", "")
		idle_anim = class_cfg.get("idle_anim", "")
		hurt_anim = class_cfg.get("hurt_anim", "")
		death_anim = class_cfg.get("death_anim", "")
		var tex_path = class_cfg.get("texture_path", "")
		if tex_path != "":
			texture_normal = load(tex_path)
		if anim_sprite:
			anim_sprite.frames = preload("res://Assets/Animations/Player.tres")
			if idle_anim != "" and anim_sprite:
				texture_normal = null
				anim_sprite.show()
				anim_sprite.play(idle_anim)
			else:
				anim_sprite.hide()
				texture_normal = load(tex_path)
	else:
		push_error("PlayerButton: Unknown or missing class_key for actor '%s'" % actor_instance.name)

	set_data(actor_instance)
	if not is_connected("pressed", Callable(self, "_on_pressed")):
		connect("pressed", Callable(self, "_on_pressed"))
