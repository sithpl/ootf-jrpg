extends Node

# Game window size
const GAME_SIZE: Vector2 = Vector2(320, 180)

# Player and global game state
var player_inventory = PlayerInventory
var player : Player = null
var player_actor : BattleActor = null
var player_perks : Array = []
var party_members: Array = [] 
var last_player_position : Vector2 = Vector2.ZERO
var last_exit : String = ""
var has_last_player_position : bool = false
var returning_from_battle : bool = false

# Initialize random seed on game start
func _ready():
	randomize()
