extends Node

const GAME_SIZE: Vector2 = Vector2(320, 180)

var player : Player = null
var last_player_position : Vector2 = Vector2.ZERO
var last_exit : String = ""
var returning_from_battle : bool = false
var has_last_player_position : bool = false
var player_perks : Array = []
var party_members: Array = []  # Holds strings/IDs of current party members

func _ready():
	randomize()
