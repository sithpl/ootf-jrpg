extends Node

func _ready():
	rebuild_party()
	for player in party:
		player.friendly = true
	Util.set_keys_to_names(enemies)
	#Util.set_keys_to_names(players)
	#DEBUG print(enemies)
	#DEBUG print(players)

# ---------- ENEMIES ----------

var mobs: Array = enemies.values()

# mobs config
static var enemies: Dictionary = {
	#_xp, _gold, _hp, _mp, _speed, _strength
	"Skeleton":         BattleActor.new( 1, 1, 1, 10, 1, 1),
	"Slime Green":      BattleActor.new( 1, 1, 1, 5, 1, 1),
}

static func get_random_enemies(count: int) -> Array:
	var keys = enemies.keys()        # e.g. ["Goofball", "Slime Green"]
	var picked = []
	for i in range(count):
		# pick a random key each loop
		var key = keys[randi() % keys.size()]
		# duplicate_custom() gives you an independent BattleActor
		picked.append(enemies[key].duplicate_custom())
	return picked

# ---------- CLASSES ----------

enum ActorClass { SOLDIER, RANGER, KNIGHT, PALADIN, MAGE, PRIEST, MAGUS }

# ActorClass config
var class_configs := {
	
	#"Soldier": { "hp_max": 50, "mp_max": 10, "strength": 4, "speed": 2, 
	#"texture_path":  "res://Assets/Players/Soldier.png", 
	#"idle_anim": "soldier_idle", "attack_anim": "soldier_melee", "hurt_anim" : "soldier_hurt", "death_anim" : "soldier_death", 
	#"skill_anim" : "soldier_skill"  },
	
	"Soldier": { "hp_max": 1, "mp_max": 1, "strength": 1, "speed": 1, 
	"texture_path":  "res://Assets/Players/Soldier.png", 
	"idle_anim": "soldier_idle", "attack_anim": "soldier_melee", "hurt_anim" : "soldier_hurt", "death_anim" : "soldier_death", 
	"skill_anim" : "soldier_skill"  },
	
	"Ranger": { "hp_max":  40, "mp_max": 20, "strength": 3,"speed": 4, 
	"texture_path": "res://Assets/Players/Ranger.png", 
	"idle_anim": "ranger_idle", "attack_anim": "ranger_ranged", "hurt_anim" : "ranger_hurt", "death_anim" : "ranger_death" },
	
	"Knight": { "hp_max": 70, "mp_max": 5, "strength": 6, "speed": 1, 
	"texture_path": "res://Assets/Players/Knight.png", 
	"idle_anim": "knight_idle", "attack_anim": "knight_melee", "hurt_anim" : "knight_hurt", "death_anim" : "Knight_death"  },
	
	"Paladin": { "hp_max": 50, "mp_max": 10, "strength": 5, "speed": 1, 
	"texture_path": "res://Assets/Players/Paladin.png", 
	"idle_anim": "paladin_idle", "attack_anim": "paladin_melee", "hurt_anim" : "paladin_hurt", "death_anim" : "paladin_death"  },
	
	"Mage": { "hp_max": 30, "mp_max": 50, "strength": 2, "speed": 2, 
	"texture_path": "res://Assets/Players/Mage.png", 
	"idle_anim": "mage_idle", "attack_anim": "mage_melee", "hurt_anim" : "mage_hurt", "death_anim" : "mage_death"  },
	
	"Priest": { "hp_max": 40, "mp_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Priest.png", 
	"idle_anim": "priest_idle", "attack_anim": "priest_melee", "hurt_anim" : "priest_hurt", "death_anim" : "priest_death"  },
	
	"Archer": { "hp_max": 40, "mp_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Archer.png", 
	"idle_anim": "archer_idle", "attack_anim": "archer_melee", "hurt_anim" : "archer_hurt", "death_anim" : "archer_death"  }
}

# ---------- CHARACTERS & PARTY ----------

var party_keys: Array[String] = ["Sith", "Sith", "Sith", "Sith"]
var party: Array[BattleActor] = []

# Assign names to classes and assign bonuses
var characters := {
	#"Sith": { "class": "Soldier", 
	#"bonuses": { "hp_max": 10, "strength": 2 }},
	"Sith": { "class": "Soldier", 
	"bonuses": {}},
	"Clabbe": { "class": "Ranger", 
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
	"Fraud": { "class": "Ranger", 
	"bonuses": { "mp_max": 5, "strength": 1}},
}

func create_character(name:String) -> BattleActor: # Create the characters, add the bonuses to base class, verify data parse
	var char_cfg = characters[name]
	var cls_name = char_cfg["class"]
	var cls_cfg  = class_configs[cls_name]

	var hp_max   = cls_cfg.hp_max    + char_cfg.bonuses.get("hp_max",0)
	var mp_max   = cls_cfg.mp_max    + char_cfg.bonuses.get("mp_max",0)
	var strength = cls_cfg.strength  + char_cfg.bonuses.get("strength",0)
	var speed    = cls_cfg.speed     + char_cfg.bonuses.get("speed",0)
	
	# Character parse debug
	#print("Creating character: ", name)
	#print("Character Config: ", char_cfg)
	#print("Class Name: ", cls_name)
	#print("Class Config: ", cls_cfg)
	#print("Final Stats -> HP:", hp_max, " MP:", mp_max, " STR:", strength, " SPD:", speed)
	
	var attack_anim = cls_cfg.get("attack_anim","<none>")
	#DEBUG print("attack_anim for %s: %s" % [name, attack_anim])
	
	var actor = BattleActor.new(0,0,hp_max,mp_max,speed,strength)
	actor.name        = name
	#actor.texture     = load(cls_cfg.texture_path)
	actor.attack_anim = attack_anim
	actor.class_key   = cls_name     # ← critical line
	return actor

func rebuild_party() -> void: # Rebuild the 'party' array from 'party_keys'
	print("Data.gd/rebuild_party() called")
	party.clear()
	for name in party_keys:
		party.append(create_character(name))

func set_party(new_keys:Array[String]) -> void: # Replace the party and rebuild
	print("Data.gd/set_party() called")
	party_keys = new_keys.duplicate()
	rebuild_party()

func swap_party_member(slot:int, new_name:String) -> void: # Swap a single slot (for menu)
	print("Data.gd/swap_party_member() called")
	if slot < 0 or slot >= party_keys.size():
		print("Invalid party slot %d" % slot)
		return
	party_keys[slot] = new_name
	party[slot]     = create_character(new_name)

func get_party() -> Array[BattleActor]: # Fetch current BattleActor list
	print("Data.gd/get_party() called")
	return party

# ---------- MUSIC ----------

enum BattleType { INTRO, NORMAL, BOSS, SPECIAL }

var current_battle_type: BattleType = BattleType.NORMAL
var intro_theme:     String = "res://Assets/Audio/Battle/intro_theme.wav"
var zone_theme:      String = "res://Assets/Audio/Battle/battle_theme.wav"
var boss_theme:      String = "res://Assets/Audio/Battle/boss_theme.wav"
var special_theme:   String = "res://Assets/Audio/Battle/special_theme.wav"
var victory_theme:   String = "res://Assets/Audio/Battle/victory_theme.wav"
var gameover_theme:  String = "res://Assets/Audio/Battle/gameover_theme.wav"

#var normal_themes: Array = [
	#"res://Audio/Battle/battle_theme1.ogg",
	#"res://Audio/Battle/battle_theme2.ogg",
#]

func get_battle_theme() -> String:
	print("Data.gd/get_battle_theme() called")
	match current_battle_type:
		BattleType.INTRO:
			return intro_theme
		BattleType.BOSS:
			return boss_theme
		BattleType.SPECIAL:
			return special_theme
		_:
			return zone_theme
