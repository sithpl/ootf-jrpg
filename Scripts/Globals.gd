extends Node

const GAME_SIZE: Vector2 = Vector2(320, 180)

var player : Player = null
var last_player_position : Vector2 = Vector2.ZERO

func _ready():
	randomize()
