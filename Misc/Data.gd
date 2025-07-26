extends Node

# Called when the node is added to the scene tree
func _ready():
	rebuild_party()
	for player in party:
		player.friendly = true
	Util.set_keys_to_names(items)
	Util.set_keys_to_names(enemies)
	#Util.set_keys_to_names(players)
	#DEBUG print(enemies)
	#DEBUG print(players)
	#inventories = [
		#Inventory.new(["Potion"])
	#]


# ---------- SCENE TRANSITIONS ----------

var tile_transitions : Dictionary = {
	# Discord
	Vector2(20,6): "Town_Discord",
	Vector2(20,5): "Town_Discord",
	Vector2(21,6): "Town_Discord",
	Vector2(21,5): "Town_Discord"
}

# ---------- ITEMS ----------

var items : Dictionary = {
	"Potion": Item.new()
}

var inventories : Array = []

# ---------- ENEMIES ----------

# Variables
var mobs                  :Array                = enemies.values()

# mobs config: Dictionary of available enemy types and their base stats.
# Format: name: BattleActor.new(_lvl, _gold, _hp, _ap, _speed, _strength)
static var enemies: Dictionary = {
	"Skeleton":         BattleActor.new( 2, 2, 5, 10, 2, 2 ),
	"Slime Green":      BattleActor.new( 1, 1, 1, 5, 1, 1 ),
	"Orc Rider":      BattleActor.new( 1, 1, 1, 5, 1, 1 ),
	"Orc Elite":      BattleActor.new( 1, 1, 1, 5, 1, 1 ),
	"Skeleton GS":      BattleActor.new( 1, 1, 1, 5, 1, 1 ),
	"Clown":      BattleActor.new( 1, 1, 1, 5, 1, 1 ),
}

# Picks a requested number of random enemy types, duplicates them so each is a fresh instance.
static func get_random_enemies(count: int) -> Array:
	#DEBUG print("Data.gd/get_random_enemies() called")
	var keys = enemies.keys()        # e.g. ["Goofball", "Slime Green"]
	var picked = []
	for i in range(count):
		# pick a random key each loop
		var key = keys[randi() % keys.size()]
		# duplicate_custom() gives you an independent BattleActor
		picked.append(enemies[key].duplicate_custom())
	return picked

static func get_random_enemies_from_weighted(count: int, weighted_list: Array) -> Array:
	#DEBUG print("Data.gd/get_random_enemies_from_weighted() called")
	var picked = []
	for i in range(count):
		var key = Util.choose_weighted(weighted_list)
		picked.append(enemies[key].duplicate_custom())
	return picked

# ---------- CLASSES ----------

# Enums
enum ActorClass { SOLDIER, RANGER, KNIGHT, PALADIN, MAGE, PRIEST, ARCHER, LANCER }

# Variables

# class_configs: Stats and asset paths for each class.
# Format: class_name: { "hp_max", "ap_max", "strength", "speed", "texture_path", animations... }
var class_configs := {
	"Soldier": { "hp_max": 50, "ap_max": 10, "strength": 4, "speed": 2, 
	"texture_path":  "res://Assets/Players/Soldier.png", 
	"idle_anim": "soldier_idle", "attack_anim": "soldier_melee", "hurt_anim" : "soldier_hurt", "death_anim" : "soldier_death", 
	"skill1_anim" : "soldier_skill1"  },

	"Ranger": { "hp_max":  40, "ap_max": 20, "strength": 3,"speed": 4, 
	"texture_path": "res://Assets/Players/Ranger.png", 
	"idle_anim": "ranger_idle", "attack_anim": "ranger_ranged", "hurt_anim" : "ranger_hurt", "death_anim" : "ranger_death" },

	"Knight": { "hp_max": 70, "ap_max": 5, "strength": 6, "speed": 1, 
	"texture_path": "res://Assets/Players/Knight.png", 
	"idle_anim": "knight_idle", "attack_anim": "knight_melee", "hurt_anim" : "knight_hurt", "death_anim" : "Knight_death"  },

	"Paladin": { "hp_max": 50, "ap_max": 10, "strength": 5, "speed": 1, 
	"texture_path": "res://Assets/Players/Paladin.png", 
	"idle_anim": "paladin_idle", "attack_anim": "paladin_melee", "hurt_anim" : "paladin_hurt", "death_anim" : "paladin_death"  },

	"Mage": { "hp_max": 30, "ap_max": 50, "strength": 2, "speed": 2, 
	"texture_path": "res://Assets/Players/Mage.png", 
	"idle_anim": "mage_idle", "attack_anim": "mage_melee", "hurt_anim" : "mage_hurt", "death_anim" : "mage_death"  },

	"Priest": { "hp_max": 40, "ap_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Priest.png", 
	"idle_anim": "priest_idle", "attack_anim": "priest_melee", "hurt_anim" : "priest_hurt", "death_anim" : "priest_death"  },

	"Archer": { "hp_max": 40, "ap_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Archer.png", 
	"idle_anim": "archer_idle", "attack_anim": "archer_ranged", "hurt_anim" : "archer_hurt", "death_anim" : "archer_death"  },

	"Lancer": { "hp_max": 40, "ap_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Lancer.png", 
	"idle_anim": "lancer_idle", "attack_anim": "lancer_melee", "hurt_anim" : "lancer_hurt", "death_anim" : "lancer_death"  },
	
	"Dogue": { "hp_max": 40, "ap_max": 30, "strength": 1, "speed": 3, 
	"texture_path": "res://Assets/Players/Dogue.png", 
	"idle_anim": "dogue_idle", "attack_anim": "dogue_melee", "hurt_anim" : "dogue_hurt", "death_anim" : "dogue_death"  },
}

# ---------- CHARACTERS & PARTY ----------

# party_keys: Names of characters currently in the party
var party_keys            :Array[String]        = ["Bili", "Glenn", "Woofshank", "Skoot"]

# party: List of BattleActor instances for the current party
var party                 :Array[BattleActor]   = []

# characters: Data for each available character including class and stat bonuses
var characters := {
	"Sith": { "class": "Soldier", 
	"bonuses": { "hp_max": 10, "strength": 2 }},
	"Clabbe": { "class": "Ranger", 
	"bonuses": { "speed": 2 }},
	"Erik": { "class": "Lancer", 
	"bonuses": { "ap_max": 15, "strength": 1 }},
	"Rage": { "class": "Knight", 
	"bonuses": { "hp_max": 5, "strength": 2 }},
	"Glenn": { "class": "Priest", 
	"bonuses": { "ap_max": 20, "speed" : 1}},
	"Clav": { "class": "Paladin", 
	"bonuses": { "hp_max": 5, "ap_max": 5, "strength": 1}},
	"Bili": { "class": "Soldier", 
	"bonuses": { "ap_max": 5, "strength": 1}},
	"Fraud": { "class": "Ranger", 
	"bonuses": { "ap_max": 5, "strength": 1}},
	"Dan": { "class": "Mage", 
	"bonuses": { "ap_max": 20, "speed" : 1}},
	"Sayree": { "class": "Paladin", 
	"bonuses": { "ap_max": 20, "speed" : 1}},
	"Skoot": { "class": "Archer", 
	"bonuses": { "ap_max": 20, "speed" : 1}},
	"Slam": { "class": "Lancer", 
	"bonuses": { "ap_max": 20, "speed" : 1}},
	"Woofshank": { "class": "Dogue", 
	"bonuses": { "ap_max": 20, "speed" : 1}},
}

# Creates a BattleActor for the given character name, applying class stats and bonuses.
func create_character(name:String) -> BattleActor:
	var char_cfg = characters[name]
	var cls_name = char_cfg["class"]
	var cls_cfg  = class_configs[cls_name]

	var hp_max   = cls_cfg.hp_max    + char_cfg.bonuses.get("hp_max",0)
	var ap_max   = cls_cfg.ap_max    + char_cfg.bonuses.get("ap_max",0)
	var strength = cls_cfg.strength  + char_cfg.bonuses.get("strength",0)
	var speed    = cls_cfg.speed     + char_cfg.bonuses.get("speed",0)
	
	# Character parse debug
	#print("Creating character: ", name)
	#print("Character Config: ", char_cfg)
	#print("Class Name: ", cls_name)
	#print("Class Config: ", cls_cfg)
	#print("Final Stats -> HP:", hp_max, " AP:", ap_max, " STR:", strength, " SPD:", speed)
	
	var attack_anim = cls_cfg.get("attack_anim","<none>")
	#DEBUG print("attack_anim for %s: %s" % [name, attack_anim])
	
	var actor = BattleActor.new(0,0,hp_max,ap_max,speed,strength)
	actor.name        = name
	#actor.texture     = load(cls_cfg.texture_path)
	actor.attack_anim = attack_anim
	actor.class_key   = cls_name     # ← critical line
	return actor

# Rebuilds the party array from the party_keys list
func rebuild_party() -> void:
	#DEBUG print("Data.gd/rebuild_party() called")
	party.clear()
	for name in party_keys:
		party.append(create_character(name))

# Replaces the party with a new set of names and rebuilds the party array
func set_party(new_keys:Array[String]) -> void:
	#DEBUG print("Data.gd/set_party() called")
	party_keys = new_keys.duplicate()
	rebuild_party()

# Swaps a party member at the given slot for a new character
func swap_party_member(slot:int, new_name:String) -> void:
	#DEBUG print("Data.gd/swap_party_member() called")
	if slot < 0 or slot >= party_keys.size():
		print("Invalid party slot %d" % slot)
		return
	party_keys[slot] = new_name
	party[slot]     = create_character(new_name)

# Returns the current party as an array of BattleActor instances
func get_party() -> Array[BattleActor]:
	#DEBUG print("Data.gd/get_party() called")
	return party
