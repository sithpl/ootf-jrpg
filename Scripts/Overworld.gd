class_name Overworld extends Node2D

# Signals
signal enemy_encountered(enemies_weighted)
signal tile_transition_entered(destination)

# Onreadys
@onready var _music               :AudioStreamPlayer = $ZoneMusic
@onready var _player              :Player            = $Player
@onready var _danger              :Danger            = $Danger
@onready var _main_map            :MainMap           = $MainMap
@onready var _enemy_spawn_areas   :EnemySpawnAreas   = $EnemySpawnAreas

var _danger_paused: bool = false

func _ready():
	if Globals.last_player_position != Vector2.ZERO:
		_player.position = Globals.last_player_position
	self.modulate = Color(0, 0, 0, 1) # Start fully black
	$AnimationPlayer.play("fade_in")  # Play fade_in animation
	await $AnimationPlayer.animation_finished

	if _music :
		_music.play()

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
	_music.stream_paused = true
	var enemies_weighted : Array = _enemy_spawn_areas.get_enemies_weighted_at_cell(_player.position)
	if enemies_weighted == null or enemies_weighted.size() == 0:
		_music.stream_paused = false
		print("No encounters available on this tile. Pausing danger counter.")
		_danger_paused = true
		return
	emit_signal("enemy_encountered", enemies_weighted)
	print("signal -> enemy_encountered emitted!")
	#print(enemies_weighted)
