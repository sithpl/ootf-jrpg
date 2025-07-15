extends Node

static var enemies: Dictionary = {
	#_xp, _gold, _hp, _mp, _speed, _strength
	"Goofball": BattleActor.new(1,1,1,10,0,1),
	"Slime Green": BattleActor.new(1,1,1,5,0,1),
}

static var players: Dictionary = {
	#_xp, _gold, _hp, _mp, _speed, _strength
	"Sith": BattleActor.new(0,0,48,10,1,4),
	"Clabbe": BattleActor.new(0,0,32,20,2,2),
	"Erik": BattleActor.new(0,0,20,53,5,1),
	"Rage": BattleActor.new(0,0,15,68,3,1),
}

var party: Array = players.values()

enum BattleType {
	NORMAL,
	BOSS,
	SPECIAL,
}

var current_battle_type: BattleType = BattleType.NORMAL
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
	for player in party:
		player.friendly = true
	Util.set_keys_to_names(enemies)
	Util.set_keys_to_names(players)
	#DEBUG print(enemies)
	#DEBUG print(players)

func get_battle_theme() -> String:
	match current_battle_type:
		BattleType.BOSS:
			return boss_theme
		BattleType.SPECIAL:
			return special_theme
		_:
			return zone_theme
