class_name Game extends Node2D

@onready var _battle_trigger_sfx : AudioStreamPlayer = $BattleTriggerSFX
@onready var _canvas_layer0 : CanvasLayer = $CanvasLayer0

const BATTLE : PackedScene = preload("res://Scenes/Battle.tscn")
const OVERWORLD : PackedScene = preload("res://Scenes/Overworld.tscn")

var _overworld : Overworld

func _ready():
	_overworld = $Overworld
	if not _overworld.is_connected("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered")):
		_overworld.connect("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered"))

func _on_overworld_enemy_encountered(enemies_weighted: Array) -> void:
	print("Game.gd/_on_overworld_enemy_encountered() called")
	Globals.last_player_position = _overworld._player.position
	_battle_trigger_sfx.play()
	Globals.player.enable(false)
	await Util.screen_flash(_canvas_layer0, "battle_start", false).tree_exiting
	remove_child.call_deferred(_overworld)

	var inst : Battle = BATTLE.instantiate()
	inst.enemies_weighted = enemies_weighted
	_canvas_layer0.add_child.call_deferred(inst)
	await inst.tree_exiting

	# Instance new overworld, connect signal
	_overworld = OVERWORLD.instantiate()
	self.call_deferred("add_child", _overworld)  # <-- FIXED: add as child of Game
	_overworld.connect("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered"))
	print("_overworld signal connected? ", _overworld.is_connected("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered")))
	Globals.player.enable(true)
