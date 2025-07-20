class_name Game extends Node2D

const BATTLE : PackedScene = preload("res://Scenes/Battle.tscn")

@onready var _overworld : Overworld = $Overworld
@onready var _canvas_layer0 : CanvasLayer = $CanvasLayer0

func _on_overworld_enemy_encountered(enemies_weighted: Array) -> void:
	print("Game.gd/_on_overworld_enemy_encountered() called")
	Globals.player.enable(false)
	await Util.screen_flash(self, "battle_start").tree_exiting
	remove_child.call_deferred(_overworld)
	
	var inst : Battle = BATTLE.instantiate()
	inst.enemies_weighted = enemies_weighted
	_canvas_layer0.add_child.call_deferred(inst)
	await inst.tree_exiting
	
	add_child(_overworld)
	Globals.player.enable(true)
