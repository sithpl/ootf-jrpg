extends Node

@onready var music_player : AudioStreamPlayer = $Music
@onready var sfx_player : AudioStreamPlayer = $SFX

# Enums
enum ThemeType { START, ZONE, INTRO, TOWN, SHOP, BATTLE, BOSS, SPECIAL, VICTORY, GAMEOVER }

# Variables
var interact_sfx          :String   = "res://Assets/Audio/UI/interact_sfx.wav"
var start_theme           :String   = "res://Assets/Audio/UI/start_theme.wav"
var zone_theme            :String   = "res://Assets/Audio/zone_theme.wav"
var intro_theme           :String   = "res://Assets/Audio/Battle/intro_theme.wav"
var town_theme            :String   = "res://Assets/Audio/town_theme.wav"
var shop_theme            :String   = "res://Assets/Audio/shop_theme.wav"
var battle_theme          :String   = "res://Assets/Audio/Battle/battle_theme.wav"
var boss_theme            :String   = "res://Assets/Audio/Battle/boss_theme.wav"
var special_theme         :String   = "res://Assets/Audio/Battle/special_theme.wav"
var victory_theme         :String   = "res://Assets/Audio/Battle/victory_theme.wav"
var gameover_theme        :String   = "res://Assets/Audio/Battle/gameover_theme.wav"

var current_theme_type    :int      = -1
var current_theme_path    :String   = ""
var current_theme         :String   = ""
var _last_theme_position  :float    = 0.0
var _is_paused            :bool     = false

# For pausing/resuming when entering shop
var previous_theme_type: int = -1

#var paused_theme_position :float = 0.0

# Volume adjustment (in decibels)
var theme_volumes := {
	ThemeType.START: -8,
	ThemeType.ZONE: -8,
	ThemeType.INTRO: -7,
	ThemeType.TOWN: -8,
	ThemeType.SHOP: -10,
	ThemeType.BATTLE: -12, 
	ThemeType.BOSS: 0,
	ThemeType.SPECIAL: 0,
	ThemeType.VICTORY: -12,
	ThemeType.GAMEOVER: 0,
}

func _ready():
	pass

func get_type_theme(theme_type: int) -> String:
	match theme_type:
		ThemeType.START:
			return start_theme
		ThemeType.ZONE:
			return zone_theme
		ThemeType.INTRO:
			return intro_theme
		ThemeType.TOWN:
			return town_theme
		ThemeType.SHOP:
			return shop_theme
		ThemeType.BATTLE:
			return battle_theme
		ThemeType.BOSS:
			return boss_theme
		ThemeType.SPECIAL:
			return special_theme
		ThemeType.VICTORY:
			return victory_theme
		ThemeType.GAMEOVER:
			return gameover_theme
		_:
			return ""

func play_type_theme(theme_type: int):
	var theme_path = get_type_theme(theme_type)
	if music_player and theme_path != "":
		music_player.stop()
		music_player.stream = load(theme_path)
		# Set volume for this theme
		if theme_volumes.has(theme_type):
			music_player.volume_db = theme_volumes[theme_type]
		else:
			music_player.volume_db = 0
		music_player.play()
		current_theme_type = theme_type
		current_theme_path = theme_path
		current_theme = theme_path
	else:
		print("music_player is null or theme_path is empty!")


func get_current_theme_type() -> int:
	return current_theme_type

func stop_music():
	if music_player:
		music_player.stop()
		current_theme_type = -1
		current_theme_path = ""
		current_theme = ""

func pause_music():
	if music_player.playing:
		_last_theme_position = music_player.get_playback_position()
		music_player.stop()
		_is_paused = true

func resume_music():
	if _is_paused and current_theme_path != "":
		music_player.play(_last_theme_position)
		_is_paused = false

func interact():
	sfx_player.stream = load(interact_sfx)
	sfx_player.play()
