extends Node

enum ActorClass { SOLDIER, ARCHER, KNIGHT, PALADIN, MAGE, PRIEST, MAGUS }

var party_keys: Array[String] = ["Sith", "Clav", "Glenn", "Rage"]
var party: Array[BattleActor] = []

static var enemies: Dictionary = {
	#_xp, _gold, _hp, _mp, _speed, _strength
	"Skeleton": BattleActor.new(1,1,1,10,1,1),
	"Slime Green": BattleActor.new(1,1,1,5,1,1),
}

#static var players: Dictionary = {
	##_xp, _gold, _hp, _mp, _speed, _strength
	#"Sith": BattleActor.new(0,0,48,10,1,4),
	#"Clabbe": BattleActor.new(0,0,32,20,2,2),
	#"Erik": BattleActor.new(0,0,20,53,5,1),
	#"Rage": BattleActor.new(0,0,15,68,3,1),
#}

# Actor_class config
var class_configs := {
	"Soldier": { "hp_max": 50, "mp_max": 10, "strength": 4, "speed": 2, 
	"texture_path":  "res://Assets/Players/Soldier.png", 
	"attack_anim": "soldier_melee" },
	"Archer": { "hp_max":  40, "mp_max": 20, "strength": 3,"speed": 4, 
	"texture_path": "res://Assets/Players/Archer.png", 
	"attack_anim": "archer_ranged" },
	"Knight": { "hp_max": 70, "mp_max": 5, "strength": 6, "speed": 1, 
	"texture_path": "res://Assets/Players/Knight.png", 
	"attack_anim": "knight_melee" },
	"Paladin": { "hp_max": 50, "mp_max": 10, "strength": 5, "speed": 1, 
	"texture_path": "res://Assets/Players/Paladin.png", 
	"attack_anim": "paladin_melee" },
	"Mage": { "hp_max": 30, "mp_max": 50, "strength": 2, "speed": 2, 
	"texture_path": "res://Assets/Players/Mage.png", 
	"attack_anim": "mage_melee" },
	"Priest": { "hp_max": 40, "mp_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Priest.png", 
	"attack_anim": "priest_melee" },
	"Magus": { "hp_max": 40, "mp_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Magus.png", 
	"attack_anim": "magus_melee" }
}

# Character name config
var characters := {
	"Sith": { "class": "Soldier", 
	"bonuses": { "hp_max": 10, "strength": 2 }},
	"Clabbe": { "class": "Archer", 
	"bonuses": { "speed": 2 }},
	"Erik": { "class": "Mage", 
	"bonuses": { "mp_max": 15, "strength": 1 }},
	"Rage": { "class": "Knight", 
	"bonuses": { "hp_max": 5, "strength": 2 }},
	"Glenn": { "class": "Priest", 
	"bonuses": { "mp_max": 20, "speed" : 1}},
	"Clav": { "class": "Paladin", 
	"bonuses": { "hp_max": 5, "mp_max": 5, "strength": 1}},
	"Bili": { "class": "Magus", 
	"bonuses": { "mp_max": 5, "strength": 1}},
}

var mobs: Array = enemies.values()

enum BattleType {
	INTRO,
	NORMAL,
	BOSS,
	SPECIAL,
}

var current_battle_type: BattleType = BattleType.NORMAL
var intro_theme: String = "res://Assets/Audio/Battle/intro_theme.wav"
var zone_theme: String = "res://Assets/Audio/Battle/battle_theme.wav"
var boss_theme: String = "res://Assets/Audio/Battle/boss_theme.wav"
var special_theme: String = "res://Assets/Audio/Battle/special_theme.wav"
var victory_theme: String = "res://Assets/Audio/Battle/victory_theme.wav"
var gameover_theme: String = "res://Assets/Audio/Battle/gameover_theme.wav"

#var normal_themes: Array = [
	#"res://Audio/Battle/battle_theme1.ogg",
	#"res://Audio/Battle/battle_theme2.ogg",
#]

func _ready():
	rebuild_party()
	for player in party:
		player.friendly = true
	Util.set_keys_to_names(enemies)
	#Util.set_keys_to_names(players)
	#DEBUG print(enemies)
	#DEBUG print(players)

func create_character(name:String) -> BattleActor:
	var char_cfg = characters[name]
	var cls_name = char_cfg["class"]
	var cls_cfg  = class_configs[cls_name]

	var hp_max   = cls_cfg.hp_max    + char_cfg.bonuses.get("hp_max",0)
	var mp_max   = cls_cfg.mp_max    + char_cfg.bonuses.get("mp_max",0)
	var strength = cls_cfg.strength  + char_cfg.bonuses.get("strength",0)
	var speed    = cls_cfg.speed     + char_cfg.bonuses.get("speed",0)

	var actor = BattleActor.new(0,0,hp_max,mp_max,speed,strength)
	actor.name       = name
	actor.texture    = load(cls_cfg.texture_path)
	actor.class_key  = cls_name     # ← critical line
	return actor

func get_battle_theme() -> String:
	match current_battle_type:
		BattleType.INTRO:
			return intro_theme
		BattleType.BOSS:
			return boss_theme
		BattleType.SPECIAL:
			return special_theme
		_:
			return zone_theme

# 3) Rebuild the 'party' array from 'party_keys'
func rebuild_party() -> void:
	party.clear()
	for name in party_keys:
		party.append(create_character(name))

# 4) Replace the party and rebuild
func set_party(new_keys:Array[String]) -> void:
	party_keys = new_keys.duplicate()
	rebuild_party()

# 5) Swap a single slot (for menu)
func swap_party_member(slot:int, new_name:String) -> void:
	if slot < 0 or slot >= party_keys.size():
		push_error("Invalid party slot %d" % slot)
		return
	party_keys[slot] = new_name
	party[slot]     = create_character(new_name)

# 6) Fetch current BattleActor list
func get_party() -> Array[BattleActor]:
	return party

static func get_random_enemies(count: int) -> Array:
	var keys = enemies.keys()        # e.g. ["Goofball", "Slime Green"]
	var picked = []
	for i in range(count):
		# pick a random key each loop
		var key = keys[randi() % keys.size()]
		# duplicate_custom() gives you an independent BattleActor
		picked.append(enemies[key].duplicate_custom())
	return picked
