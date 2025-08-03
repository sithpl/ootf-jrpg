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
# Format: name: BattleActor.new(_lvl, _gold, _hp, _ap, _attack, _defense, _magic, _speed)
static var enemies: Dictionary = {
	"Skeleton"          :BattleActor.new( 2, 2, 5, 10, 1, 1, 2, 2 ),
	"Slime Green"       :BattleActor.new( 1, 1, 1, 5, 1, 1, 1, 1 ),
	"Orc Rider"         :BattleActor.new( 1, 1, 20, 5, 8, 1, 1, 5 ),
	"Orc Elite"         :BattleActor.new( 1, 1, 25, 5, 10, 1, 1, 10 ),
	"Skeleton GS"       :BattleActor.new( 1, 1, 1, 5, 1, 1, 1, 1 ),
	"Clown"             :BattleActor.new( 1, 1, 1, 5, 1, 1, 1, 1 ),
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
enum ActorClass { SOLDIER, RANGER, KNIGHT, PALADIN, MAGE, PRIEST, ARCHER, LANCER, DOGUE }

# class_configs: Stats and asset paths for each class.
# Format: class_name: { "base_hp", "base_ap", "attack", "defense", "magic", "speed", "texture_path", animations... }
var class_configs := {
	"Soldier": { 
		"base_hp": 50, 
		"base_ap": 10, 
		"attack": 4, 
		"defense": 3, 
		"magic": 1, 
		"speed": 2,
		"texture_path":  "res://Assets/Players/Soldier.png", 
		"idle_anim": "soldier_idle", 
		"attack_anim": "soldier_melee", 
		"hurt_anim" : "soldier_hurt", 
		"death_anim" : "soldier_death", 
		"skill1_anim" : "soldier_skill1"
	},

	"Ranger": { 
		"base_hp": 40, 
		"base_ap": 20, 
		"attack": 3, 
		"defense": 2, 
		"magic": 2, 
		"speed": 4,
		"texture_path": "res://Assets/Players/Ranger.png", 
		"idle_anim": "ranger_idle", 
		"attack_anim": "ranger_ranged", 
		"hurt_anim" : "ranger_hurt", 
		"death_anim" : "ranger_death"
	},

	"Knight": { 
		"base_hp": 70, 
		"base_ap": 5, 
		"attack": 6, 
		"defense": 5, 
		"magic": 1, 
		"speed": 1,
		"texture_path": "res://Assets/Players/Knight.png", 
		"idle_anim": "knight_idle", 
		"attack_anim": "knight_melee", 
		"hurt_anim" : "knight_hurt", 
		"death_anim" : "knight_death"
	},

	"Paladin": { 
		"base_hp": 50, 
		"base_ap": 10, 
		"attack": 5, 
		"defense": 4, 
		"magic": 3, 
		"speed": 1,
		"texture_path": "res://Assets/Players/Paladin.png", 
		"idle_anim": "paladin_idle", 
		"attack_anim": "paladin_melee", 
		"hurt_anim" : "paladin_hurt", 
		"death_anim" : "paladin_death"
	},

	"Mage": { 
		"base_hp": 30, 
		"base_ap": 50, 
		"attack": 1, 
		"defense": 1, 
		"magic": 7, 
		"speed": 2,
		"texture_path": "res://Assets/Players/Mage.png", 
		"idle_anim": "mage_idle", 
		"attack_anim": "mage_melee", 
		"hurt_anim" : "mage_hurt", 
		"death_anim" : "mage_death"
	},

	"Priest": { 
		"base_hp": 40, 
		"base_ap": 30, 
		"attack": 2, 
		"defense": 2, 
		"magic": 6, 
		"speed": 3,
		"texture_path": "res://Assets/Players/Priest.png", 
		"idle_anim": "priest_idle", 
		"attack_anim": "priest_melee", 
		"hurt_anim" : "priest_hurt", 
		"death_anim" : "priest_death"
	},

	"Archer": { 
		"base_hp": 40, 
		"base_ap": 30, 
		"attack": 3, 
		"defense": 2, 
		"magic": 2, 
		"speed": 3,
		"texture_path": "res://Assets/Players/Archer.png", 
		"idle_anim": "archer_idle", 
		"attack_anim": "archer_ranged", 
		"hurt_anim" : "archer_hurt", 
		"death_anim" : "archer_death"
	},

	"Lancer": { 
		"base_hp": 40, 
		"base_ap": 30, 
		"attack": 4, 
		"defense": 3, 
		"magic": 1, 
		"speed": 3,
		"texture_path": "res://Assets/Players/Lancer.png", 
		"idle_anim": "lancer_idle", 
		"attack_anim": "lancer_melee", 
		"hurt_anim" : "lancer_hurt", 
		"death_anim" : "lancer_death"
	},

	"Dogue": { 
		"base_hp": 40, 
		"base_ap": 30, 
		"attack": 3, 
		"defense": 2, 
		"magic": 2, 
		"speed": 3,
		"texture_path": "res://Assets/Players/Dogue.png", 
		"idle_anim": "dogue_idle", 
		"attack_anim": "dogue_melee", 
		"hurt_anim" : "dogue_hurt", 
		"death_anim" : "dogue_death"
	}
}

# ---------- CHARACTERS & PARTY ----------

# party_keys: Names of characters currently in the party
var party_keys            :Array[String]        = ["Cracker", "Kanili", "Dan", "Woofshank"]

# party: List of BattleActor instances for the current party
var party                 :Array[BattleActor]   = []

# personalities: List of personality types with associated bonuses
var personalities := {
	"Brave":        { "attack": 2, "defense": 1 },
	"Clever":       { "magic": 2, "speed": 1 },
	"Loyal":        { "defense": 2, "base_hp": 5 },
	"Energetic":    { "speed": 2, "base_ap": 5 },
	"Kind":         { "magic": 1, "base_ap": 3 },
	"Curious":      { "magic": 1, "attack": 1 },
	"Calm":         { "defense": 1, "base_hp": 2 },
	"Cheerful":     { "speed": 1, "base_ap": 2 },
	"Bold":         { "attack": 2, "speed": 1 },
	"Wise":         { "magic": 2, "defense": 1 },
	"Optimistic":   { "base_hp": 3, "defense": 1 },
	"Adventurous":  { "speed": 2, "attack": 1 },
	"Resourceful":  { "base_ap": 3, "magic": 1 },
	"Charismatic":  { "magic": 1, "defense": 1, "attack": 1 },
	"Patient":      { "defense": 2, "base_hp": 2 },
	"Creative":     { "magic": 2, "base_ap": 1 },
	"Compassionate":{ "base_ap": 2, "magic": 1 },
	"Quick-witted": { "speed": 2, "attack": 1 },
	"Steadfast":    { "defense": 2, "attack": 1 },
	"Supportive":   { "base_hp": 2, "base_ap": 2 },
	"Focused":      { "attack": 1, "defense": 1, "speed": 1 },
	"Ambitious":    { "attack": 2, "base_ap": 1 },
	"Gentle":       { "magic": 1, "defense": 1 },
	"Inspiring":    { "base_hp": 2, "attack": 1 },
	"Trustworthy":  { "defense": 2 },
	"Diligent":     { "base_ap": 2, "defense": 1 },
	"Confident":    { "attack": 2, "speed": 1 },
	"Playful":      { "speed": 2, "base_ap": 1 }
}

# characters: Data for each available character including class and stat bonuses
var characters := {
	"Cracker": { "class": "Soldier", 
	"personality": "Steadfast",
	"portrait": "res://Assets/Portraits/prt0004.png"},
	
	"Kanili": { "class": "Ranger", 
	"personality": "Compassionate",
	"portrait": "res://Assets/Portraits/prt0019.png"},
	
	"Clabbe": { "class": "Ranger", 
	"personality": "Brave",
	"portrait": "res://Assets/Portraits/prt0014.png"},
	
	"Erik": { "class": "Lancer", 
	"personality": "Cheerful",
	"portrait": "res://Assets/Portraits/prt0018.png"},
	
	"Rage": { "class": "Knight", 
	"personality": "Curious",
	"portrait": "res://Assets/Portraits/prt0016.png"},
	
	"Glenn": { "class": "Priest", 
	"personality": "Calm",
	"portrait": "res://Assets/Portraits/prt0005.png"},
	
	"Clav": { "class": "Paladin", 
	"personality": "Charismatic",
	"portrait": "res://Assets/Portraits/prt0011.png"},
	
	"Bili": { "class": "Soldier", 
	"personality": "Patient",
	"portrait": "res://Assets/Portraits/prt0022.png"},
	
	"Fraud": { "class": "Ranger", 
	"personality": "Quick-witted",
	"portrait": "res://Assets/Portraits/prt0015.png"},
	
	"Dan": { "class": "Mage", 
	"personality": "Creative",
	"portrait": "res://Assets/Portraits/prt0012.png"},
	
	"Sayree": { "class": "Paladin", 
	"personality": "Supportive",
	"portrait": "res://Assets/Portraits/prt0009.png"},
	
	"Skoot": { "class": "Archer", 
	"personality": "Playful",
	"portrait": "res://Assets/Portraits/prt0006.png"},
	
	"Slam": { "class": "Lancer", 
	"personality": "Confident",
	"portrait": "res://Assets/Portraits/prt0021.png"},
	
	"Woofshank": { "class": "Dogue", 
	"personality": "Bold",
	"portrait": "res://Assets/Portraits/prt0104.png"},
}

# Creates a BattleActor for the given character name, applying class stats and bonuses.
func create_character(name: String) -> BattleActor:
	var char_cfg = characters[name]
	var cls_name = char_cfg["class"]
	var cls_cfg = class_configs[cls_name]
	var pers_cfg = personalities.get(char_cfg.get("personality", ""), {})

	# Get bonuses from character or their personality, if present
	var bonus_dict = {}
	if char_cfg.has("bonuses"):
		bonus_dict = char_cfg.bonuses
	if char_cfg.has("personality"):
		var pers = char_cfg.personality
		if personalities.has(pers):
			# Merge bonuses from personality into bonus_dict
			for k in personalities[pers]:
				bonus_dict[k] = bonus_dict.get(k, 0) + personalities[pers][k]

	# Use new stat field names and apply bonuses
	var hp_max   = cls_cfg.base_hp   + bonus_dict.get("base_hp", 0)
	var ap_max   = cls_cfg.base_ap   + bonus_dict.get("base_ap", 0)
	var attack   = cls_cfg.attack    + bonus_dict.get("attack", 0)
	var defense  = cls_cfg.defense   + bonus_dict.get("defense", 0)
	var magic    = cls_cfg.magic     + bonus_dict.get("magic", 0)
	var speed    = cls_cfg.speed     + bonus_dict.get("speed", 0)

	var attack_anim = cls_cfg.get("attack_anim", "<none>")

	var actor = BattleActor.new(0, 0, hp_max, ap_max, attack, defense, magic, speed)
	actor.name        = name
	actor.class_key   = cls_name
	actor.attack_anim = attack_anim
	actor.hp_max      = hp_max
	actor.ap_max      = ap_max
	actor.attack      = attack
	actor.defense     = defense
	actor.magic       = magic
	actor.speed       = speed

	return actor

# Rebuilds the party array from the party_keys list
func rebuild_party() -> void:
	party.clear()
	for i in range(party_keys.size()):
		var name = party_keys[i]
		var actor = create_character(name)
		var equipment = PlayerInventory.get_equipment_for(name)
		PlayerInventory.apply_equipment_bonuses(actor, equipment)
		actor.friendly = true   # <--- ADD THIS LINE
		party.append(actor)
	if party.size() > 0:
		Globals.player_actor = party[0]

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
