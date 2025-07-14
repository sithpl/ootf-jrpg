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

func _ready():
	for player in party:
		player.friendly = true
	Util.set_keys_to_names(enemies)
	Util.set_keys_to_names(players)
	#DEBUG print(enemies)
	#DEBUG print(players)
