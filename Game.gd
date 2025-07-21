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

func transition_scene(scene: Node):
	Globals.player.enable(false)
	remove_child(_overworld)
	await get_tree().create_timer(0.5).timeout
	
	add_child(scene)
	Globals.player = _overworld._player
	Globals.player.enable(true)
	# After adding the new scene, try to disable Danger

func _on_overworld_enemy_encountered(enemies_weighted: Array) -> void:
	overworld_music(true)
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

# THIS DOESN'T WORK AND I AM OUT OF IDEAS
func overworld_music(paused: bool):
	var overworld_scene = get_node("Overworld")
	if overworld_scene:
		var audio_player = overworld_scene.get_node("ZoneMusic")
		if audio_player:
			if paused and audio_player.playing:
				audio_player.stream_paused = true
				print("Zone music paused")
			elif not paused and audio_player.stream_paused:
				audio_player.stream_paused = false
				print("Zone music resumed")

func _on_overworld_tile_transition_entered(destination: String) -> void:
	var scene : Node = load("res://Scenes/" + destination + ".tscn").instantiate()
	print(scene)
	transition_scene(scene)
