class_name NPC extends Node2D

@export var npc_id: String
@export var recruitable: bool = false
@export var npc_anim: String
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var npc_can_interact = false
var dialogue_index := 0

# All NPC data in one dictionary
var npc_database := {
	"kanili": {
		"name": "Kanili",
		"recruitable": true,
		"default_dialogue": ["...", "", "Why are you talking to me?", ""],
		"hoegetter_dialogue": {
			"default": "*blushes*",
			"Clav": "Is that the black chad adonis himself?"
		},
		"portrait": "res://Assets/Portraits/alice.png",
		"animation_set": "female_actor_1"
	},
	"cracker": {
		"name": "Cracker",
		"recruitable": false,
		"default_dialogue": ["Hey.", "", "Please stop bothering me.", ""],
		"hoegetter_dialogue": {
			"default": "I don't swing that way, bro. Not for you...",
			"Rick": "I will literally suck your dick right now bro."
		},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_villager_2"
	},
	"shadow": {
		"name": "Shadow",
		"recruitable": false,
		"default_dialogue": ["Wanna play some Fortie?", "", "CHICKEN JOCKEY!", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "boy_villager_1"
	},
	"drak": {
		"name": "Drak",
		"recruitable": false,
		"default_dialogue": ["kys", "", "SNEEEEEEED!", "", "I love Bonbi!", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_goblin_1"
	},
	"friz": {
		"name": "Friz",
		"recruitable": false,
		"default_dialogue": ["I'm a stupid bitch!", "", "jk go fuck yourself", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_actor_3"
	},
	"erik": {
		"name": "Erik",
		"recruitable": false,
		"default_dialogue": ["Human. Sword. Horse. Gamer.", "", "OLUTTTT!", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_actor_4"
	},
	"dan": {
		"name": "Dan",
		"recruitable": false,
		"default_dialogue": ["I'm a very attractive man.", "", "And I make a lot of money.", "", "lol loser", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_actor_1"
	},
	"fraud": {
		"name": "Fraud",
		"recruitable": false,
		"default_dialogue": ["Did I order an annoying bitch?", "", "Did I order another one?", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_actor_5"
	},
}

var npc_animations = {
	"male_villager_1": {
		"move_up": "male_villager_1_UP",
		"move_down": "male_villager_1_DOWN",
		"move_left": "male_villager_1_LEFT",
		"move_right": "male_villager_1_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"male_villager_2": {
		"move_up": "male_villager_2_UP",
		"move_down": "male_villager_2_DOWN",
		"move_left": "male_villager_2_LEFT",
		"move_right": "male_villager_2_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"male_villager_3": {
		"move_up": "male_villager_3_UP",
		"move_down": "male_villager_3_DOWN",
		"move_left": "male_villager_3_LEFT",
		"move_right": "male_villager_3_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"female_villager_1": {
		"move_up": "female_villager_1_UP",
		"move_down": "female_villager_1_DOWN",
		"move_left": "female_villager_1_LEFT",
		"move_right": "female_villager_1_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"boy_villager_1": {
		"move_up": "boy_villager_1_UP",
		"move_down": "boy_villager_1_DOWN",
		"move_left": "boy_villager_1_LEFT",
		"move_right": "boy_villager_1_RIGHT",
		"scale": Vector2(0.9, 0.9)
	},
	"male_actor_1": {
		"move_up": "male_actor_1_UP",
		"move_down": "male_actor_1_DOWN",
		"move_left": "male_actor_1_LEFT",
		"move_right": "male_actor_1_RIGHT",
		"scale": Vector2(0.7, 0.7)
	},
	"male_actor_2": {
		"move_up": "male_actor_2_UP",
		"move_down": "male_actor_2_DOWN",
		"move_left": "male_actor_2_LEFT",
		"move_right": "male_actor_2_RIGHT",
		"scale": Vector2(0.7, 0.7)
	},
	"male_actor_3": {
		"move_up": "male_actor_3_UP",
		"move_down": "male_actor_3_DOWN",
		"move_left": "male_actor_3_LEFT",
		"move_right": "male_actor_3_RIGHT",
		"scale": Vector2(0.7, 0.7)
	},
	"male_actor_4": {
		"move_up": "male_actor_4_UP",
		"move_down": "male_actor_4_DOWN",
		"move_left": "male_actor_4_LEFT",
		"move_right": "male_actor_4_RIGHT",
		"scale": Vector2(0.7, 0.7)
	},
	"male_actor_5": {
		"move_up": "male_actor_5_UP",
		"move_down": "male_actor_5_DOWN",
		"move_left": "male_actor_5_LEFT",
		"move_right": "male_actor_5_RIGHT",
		"scale": Vector2(1.1, 1.1)
	},
	"female_actor_1": {
		"move_up": "female_actor_1_UP",
		"move_down": "female_actor_1_DOWN",
		"move_left": "female_actor_1_LEFT",
		"move_right": "female_actor_1_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"male_clergy_1": {
		"move_up": "male_clergy_1_UP",
		"move_down": "male_clergy_1_DOWN",
		"move_left": "male_clergy_1_LEFT",
		"move_right": "male_clergy_1_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"male_goblin_1": {
		"move_up": "male_goblin_1_UP",
		"move_down": "male_goblin_1_DOWN",
		"move_left": "male_goblin_1_LEFT",
		"move_right": "male_goblin_1_RIGHT",
		"scale": Vector2(0.6, 0.6)
	},
	# Add more sets as needed
}

func _ready():
	if npc_database.has(npc_id):
		var data = npc_database[npc_id]
		recruitable = data.get("recruitable", false)
		npc_anim = data.get("animation_set", npc_anim)
		# Set the scale from the animation set, if defined
		if npc_animations.has(npc_anim):
			animated_sprite.scale = npc_animations[npc_anim].get("scale", Vector2(1, 1))
	else:
		recruitable = false
	set_spawn_direction("move_down")

func get_dialogue(perks: Array, party_members: Array) -> String:
	if not npc_database.has(npc_id):
		return "..."
	var data = npc_database[npc_id]
	var dialogue = data.get("default_dialogue", ["..."])

	# Hoegetter logic
	if "hoegetter" in perks and data.has("hoegetter_dialogue"):
		var lm_dialogue = data["hoegetter_dialogue"]
		for member in party_members:
			if lm_dialogue.has(member):
				return lm_dialogue[member]
		if lm_dialogue.has("default"):
			return lm_dialogue["default"]
	
	# Cycle through default dialogue
	if dialogue.size() > 0:
		var dialogue_line = dialogue[dialogue_index]
		dialogue_index = (dialogue_index + 1) % dialogue.size()
		return dialogue_line
	return "..."

func get_formatted_dialogue(perks: Array, party_members: Array) -> String:
	var name = npc_database.get(npc_id, {}).get("name", "???")
	var line = get_dialogue(perks, party_members)
	return "%s: %s" % [name, line]

func should_spawn() -> bool:
	# Example: Only spawn if not recruited
	if recruitable and Globals.party_members.has(npc_id):
		return false
	return true

func set_spawn_direction(direction: String):
	if npc_animations.has(npc_anim):
		var anim_name = npc_animations[npc_anim].get(direction, "")
		if anim_name != "":
			animated_sprite.set_animation(anim_name)
			
			# Set DOWN animation and loop it at 2 FPS
			#animated_sprite.sprite_frames.set_animation_speed(anim_name, 2)
			#animated_sprite.sprite_frames.set_animation_loop(anim_name,true)
			#animated_sprite.play(anim_name)

func _on_interaction_range_body_entered(body):
	if body.is_in_group("player"):
		npc_can_interact = true

func _on_interaction_range_body_exited(body):
	if body.is_in_group("player"):
		npc_can_interact = false

func _unhandled_input(event):
	if npc_can_interact and event.is_action_pressed("ui_accept"):
		#DEBUG print("NPC: Interact pressed, calling Game.show_dialogue")
		var game = get_node("/root/Game")
		game.show_dialogue(self)
