class_name Overworld extends Node2D

# Signals
signal enemy_encountered(enemies_weighted)

# Onreadys
@onready var _player              :Player          = $Player
@onready var _danger              :Danger          = $Danger
@onready var _main_map            :MainMap         = $MainMap
@onready var _enemy_spawn_areas   :EnemySpawnAreas = $EnemySpawnAreas


func _on_player_moved(pos: Vector2, run_factor: float) -> void:
	#DEBUG print("Overworld.gd/_on_player_moved() called")
	_danger.countdown(_main_map.get_threat_level(pos) * run_factor)

func _on_danger_limit_reached() -> void:
	print("Overworld.gd/on_danger_limit_reached() called")
	var enemies_weighted : Array = _enemy_spawn_areas.get_enemies_weighted_at_cell(_player.position)
	emit_signal("enemy_encountered", enemies_weighted)
	print(enemies_weighted)
