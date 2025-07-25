extends Node

@onready var music_player : AudioStreamPlayer = $Music
@onready var sfx_player : AudioStreamPlayer = $SFX

# Enums
enum ThemeType { ZONE, INTRO, TOWN, BATTLE, BOSS, SPECIAL, VICTORY, GAMEOVER }

# Variables
var interact_sfx          :String = "res://Assets/Audio/interact_sfx.wav"
var zone_theme            :String = "res://Assets/Audio/zone_theme.wav"
var intro_theme           :String = "res://Assets/Audio/Battle/intro_theme.wav"
var town_theme            :String = "res://Assets/Audio/town_theme.wav"
var battle_theme          :String = "res://Assets/Audio/Battle/battle_theme.wav"
var boss_theme            :String = "res://Assets/Audio/Battle/boss_theme.wav"
var special_theme         :String = "res://Assets/Audio/Battle/special_theme.wav"
var victory_theme         :String = "res://Assets/Audio/Battle/victory_theme.wav"
var gameover_theme        :String = "res://Assets/Audio/Battle/gameover_theme.wav"

# Volume adjustment (in decibels)
var theme_volumes := {
	ThemeType.ZONE: -8,
	ThemeType.INTRO: -7,
	ThemeType.TOWN: -8,
	ThemeType.BATTLE: -12, 
	ThemeType.BOSS: 0,
	ThemeType.SPECIAL: 0,
	ThemeType.VICTORY: -12,
	ThemeType.GAMEOVER: 0,
}

func _ready():
	pass

# Returns the path for the current battle theme music based on battle type
func get_type_theme(theme_type: int) -> String:
	match theme_type:
		ThemeType.ZONE:
			return zone_theme
		ThemeType.INTRO:
			return intro_theme
		ThemeType.TOWN:
			return town_theme
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
			return zone_theme

func play_type_theme(theme_type: int):
	var theme_path = get_type_theme(theme_type)
	if music_player and theme_path != "":
		music_player.stream = load(theme_path)
		# Set volume for this theme
		if theme_volumes.has(theme_type):
			music_player.volume_db = theme_volumes[theme_type]
		else:
			music_player.volume_db = 0
		music_player.play()
	else:
		print("music_player is null or theme_path is empty!")

func stop_music():
	if music_player:
		music_player.stop()

func pause_music():
	if music_player:
		music_player.stream_paused = true

func resume_music():
	if music_player:
		music_player.stream_paused = false

func interact():
	sfx_player.stream = load(interact_sfx)
	sfx_player.play()
