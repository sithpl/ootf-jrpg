class_name Overworld extends Node2D

# Signals
signal enemy_encountered(enemies_weighted)
signal tile_transition_entered(destination)

# Onreadys
@onready var _player              :Player            = $Player
@onready var _danger              :Danger            = $Danger
@onready var _main_map            :MainMap           = $MainMap
@onready var _enemy_spawn_areas   :EnemySpawnAreas   = $EnemySpawnAreas
@onready var area_name : String = "World Map"

var area_theme = MusicManager.ThemeType.ZONE
var _danger_paused: bool = false

func _ready():
	if get_name() == "Overworld" and Globals.last_player_position != Vector2.ZERO:
		_player.position = Globals.last_player_position
	if area_name != null:
		TextUi.show_area_name(area_name)
	overworld_entrance()
	if MusicManager.music_player.stream_paused:
		MusicManager.resume_music()
	else:
		MusicManager.play_type_theme(area_theme)
	_danger_paused = false            # <-- Resume danger ticking after returning

func _on_player_moved(pos: Vector2, run_factor: float) -> void:
	#DEBUG print("Overworld.gd/_on_player_moved() called")
	var destination : String = _main_map.get_tile_transition_destination(pos)
	if destination:
		emit_signal("tile_transition_entered", destination)
	else:
		_danger.countdown(_main_map.get_threat_level(pos) * run_factor)

func _on_danger_limit_reached() -> void:
	print("Overworld.gd/on_danger_limit_reached() called")
	var enemies_weighted : Array = _enemy_spawn_areas.get_enemies_weighted_at_cell(_player.position)
	if enemies_weighted == null or enemies_weighted.size() == 0:
		print("No encounters available on this tile. Pausing danger counter.")
		_danger_paused = true
		return
	emit_signal("enemy_encountered", enemies_weighted)
	print("signal -> enemy_encountered emitted!")
	#DEBUG print(enemies_weighted)

func overworld_entrance():
	self.modulate = Color(0, 0, 0, 1) # Start fully black
	$AnimationPlayer.play("fade_in")  # Play fade_in animation
	await $AnimationPlayer.animation_finished
