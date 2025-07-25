class_name Game extends Node2D

@onready var _battle_trigger_sfx : AudioStreamPlayer = $BattleTriggerSFX
@onready var _canvas_layer0 : CanvasLayer = $CanvasLayer0

const BATTLE : PackedScene = preload("res://Scenes/Battle.tscn")
const OVERWORLD : PackedScene = preload("res://Scenes/Overworld.tscn")

var _world_map : Node2D

func _ready():
	_world_map = $Overworld
	if not _world_map.is_connected("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered")):
		_world_map.connect("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered"))
	if not _world_map.is_connected("tile_transition_entered", Callable(self, "_on_overworld_tile_transition_entered")):
		_world_map.connect("tile_transition_entered", Callable(self, "_on_overworld_tile_transition_entered"))

func transition_scene(scene: Node, destination: String = ""):
	#DEBUG print("Game.gd/transition_scene() called")
	Globals.player.enable(false)
	await play_overworld_animation("fade_out")
	
	# Remove old world map if it's our child
	if _world_map.get_parent() == self:
		remove_child.call_deferred(_world_map)
	await get_tree().create_timer(0.1).timeout

	var player_node = scene.get_node_or_null("Player")
	
	if Globals.returning_from_battle:
		if player_node:
			print("Returning from battle, restoring last battle position")
			player_node.position = Globals.last_player_position
		Globals.returning_from_battle = false
		# DO NOT clear last_player_position here!
	else:
		# Map-to-map transition: clear last_player_position
		Globals.has_last_player_position = false
	
	# Positioning logic for Overworld and Towns
	var entry_point_name = Globals.last_exit
	#DEBUG print("Trying entry point:", entry_point_name)
	if entry_point_name != null and entry_point_name != "":
		var entry = scene.get_node_or_null("EntryPoints/" + entry_point_name)
		#DEBUG print("Entry found:", entry)
		if entry and player_node:
			player_node.position = entry.position
		else:
			#DEBUG print("Entry point not found, using fallback.")
			player_node.position = Vector2(0,0)
	elif destination.begins_with("Town"):
		var scene_name = scene.name
		if destination.begins_with("Town") or scene_name.begins_with("Town"):
			#DEBUG print("Town destination detected")
			var town_entry = scene.get_node_or_null("EntryPoints/Entrance")
			#DEBUG print("Town entry found:", town_entry)
			if town_entry and player_node:
				player_node.position = town_entry.position

	if player_node:
		Globals.player = player_node

	add_child(scene)
	_world_map = scene
	if _world_map.has_signal("enemy_encountered"):
		if not _world_map.is_connected("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered")):
			_world_map.connect("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered"))
		if _world_map.has_signal("tile_transition_entered"):
			if not _world_map.is_connected("tile_transition_entered", Callable(self, "_on_overworld_tile_transition_entered")):
				_world_map.connect("tile_transition_entered", Callable(self, "_on_overworld_tile_transition_entered"))

func _on_overworld_enemy_encountered(enemies_weighted: Array) -> void:
	#DEBUG print("Game.gd/_on_overworld_enemy_encountered() called")
	MusicManager.pause_music()
	Globals.last_player_position = _world_map._player.position
	_battle_trigger_sfx.play()
	Globals.player.enable(false)
	await Util.screen_flash(_canvas_layer0, "battle_start", false).tree_exiting
	remove_child.call_deferred(_world_map)

	var inst : Battle = BATTLE.instantiate()
	inst.enemies_weighted = enemies_weighted
	_canvas_layer0.add_child.call_deferred(inst)
	await inst.tree_exiting
	Globals.returning_from_battle

	# Instance new overworld, connect signal
	_world_map = OVERWORLD.instantiate()
	self.call_deferred("add_child", _world_map)
	_world_map.connect("enemy_encountered", Callable(self, "_on_overworld_enemy_encountered"))
	_world_map.connect("tile_transition_entered", Callable(self, "_on_overworld_tile_transition_entered"))
	Globals.player.enable(true)

func _on_overworld_tile_transition_entered(destination: String) -> void:
	# Only clear when not returning from battle
	if not Globals.returning_from_battle:
		Globals.last_player_position = Vector2.ZERO  # or your chosen sentinel, or set your validity flag to false

	if destination == _world_map.name:
		transition_scene(_world_map)
	else:
		var scene : Node = load("res://Scenes/" + destination + ".tscn").instantiate()
		if scene.has_signal("tile_transition_entered"):
			print("Connected tile_transition_entered for", scene)
			scene.connect("tile_transition_entered", Callable(self, "_on_overworld_tile_transition_entered"))
		#DEBUG print(scene)
		transition_scene(scene, destination)

func play_overworld_animation(anim_name: String):
	var overworld = get_node_or_null("Overworld")
	if overworld:
		var anim_player = overworld.get_node("AnimationPlayer")
		if anim_player:
			anim_player.play(anim_name)

func show_dialogue(npc: NPC):
	#DEBUG print("Game.gd/show_dialogue() called")
	print("Game.show_dialogue called for: ", npc.npc_id)
	MusicManager.interact()
	Globals.player.movement_locked = true
	print("movement_locked = ", Globals.player.movement_locked)

	var perks = Globals.player_perks if Globals.player_perks != null else []
	var party_members = Globals.party_members if Globals.party_members != null else []
	var dialogue = npc.get_formatted_dialogue(perks, party_members)

	print("Input.is_action_pressed(ui_accept): ", Input.is_action_pressed("ui_accept"))
	TextUi.show_dialogue_box(dialogue)
	#DEBUG print("Game.gd/show_dialogue() -> TextUI.gd/show_dialogue_box() called")
	#DEBUG print(dialogue)
	
	print("Waiting for confirmation...")
	await TextUi.confirmed
	print("Confirmed signal received!")
	
	TextUi.hide_dialogue_box()
	
	#DEBUG print("Game.gd/show_dialogue() -> TextUI.gd/hide_dialogue_box() called")
	Globals.player.movement_locked = false
	print("movement_locked = ", Globals.player.movement_locked)

# Waits for a fresh press, not just the key being down
func _wait_for_confirm():
	while Input.is_action_pressed(&"ui_accept"):
		await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed(&"ui_accept"):
			emit_signal("confirmed")
			break
