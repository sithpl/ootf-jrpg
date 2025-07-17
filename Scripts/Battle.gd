class_name Battle extends Control

enum States {
	INTRO,
	IDLE,
	PLAYER_SELECT,
	PLAYER_TARGET,
	ENEMY_TURN,
	VICTORY,
	GAMEOVER
}

enum Actions {
	FIGHT,
	MAGIC,
	ITEM,
	DEFEND
}

@export var transition_time := 0.7

const MAX_LOG_LINES := 3

# Battle flow
var state: States = States.IDLE
var _orig_positions := {}
var turn_order: Array[BattleActor] = []
var current_turn_idx: int = 0
var current_actor: BattleActor = null
var action: Actions = Actions.FIGHT
var action_log: Array[String] = []
var EnemyButtonScene: PackedScene = preload("res://scenes/EnemyButton.tscn")
var _enemy_info_nodes: Array[Label] = []

# UI nodes
@onready var _battle_music: AudioStreamPlayer = $BattleMusic
@onready var _log_label: Label = $ActionLogLabel
@onready var _gui: Control = $GUIMargin
@onready var _options: WindowDefault = $Options
@onready var _options_menu: Menu = $Options/Options
@onready var _enemies_menu: Menu = $Enemies
@onready var _enemy_slots := $Enemies.get_children()
@onready var _enemy_info_scroll : ScrollContainer = $GUIMargin/Bottom/Enemies/ScrollContainer
@onready var _enemy_info_vbox   : VBoxContainer = _enemy_info_scroll.get_node("MarginContainer/VBoxContainer")
@onready var _players_menu: Menu = $Players
@onready var _menu_cursor: MenuCursor = $MenuCursor
@onready var _down_cursor: Sprite2D = $DownCursor

func _ready():
	_options.hide()
	_down_cursor.hide()
	_gui.hide()
	call_deferred("_play_intro")  # Defer so _ready finishes first

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state == States.PLAYER_TARGET:
		_cancel_target_selection()

func _log_action(text: String) -> void:
	action_log.append(text)
	if action_log.size() > MAX_LOG_LINES:
		action_log.pop_front()
	_log_label.text = "\n".join(action_log)

func _stash_and_offset_buttons() -> void:
	var screen_w = get_viewport_rect().size.x

	# Players slide in from left
	for btn in _players_menu.get_buttons():
		_orig_positions[btn] = btn.position
		btn.position.x += screen_w

	# Enemies slide in from right
	for btn in _enemies_menu.get_buttons():
		_orig_positions[btn] = btn.position
		btn.position.x -= screen_w

func _play_intro() -> void:
	print("Battle.gd/_play_intro() called")
	state = States.INTRO

	# 0) Spawn between 2 and 6 enemies (duplicates allowed)
	var spawn_count = randi_range(2, 6)
	_spawn_random_enemies(spawn_count)

	# 1) Play ONLY the intro theme
	var theme_stream = load(Data.intro_theme)
	if theme_stream:
		_battle_music.stream = theme_stream
		_battle_music.play()

	# 2) Cache orig positions & move offscreen
	_stash_and_offset_buttons()

	# 3) A small delay, then slide players/enemies
	await get_tree().create_timer(0.5).timeout
	await _slide_group(_players_menu.get_buttons(), 0.3)
	await get_tree().create_timer(1.0).timeout
	await _slide_group(_enemies_menu.get_buttons(), 0.6)

	# 4) Show the UI and start the turn loop (no more theme resets here)
	_gui.show()
	_start_battle()

func _start_battle() -> void:
	print("Battle.gd/_start_battle() called")
	# 1) Play battle theme
	var theme_path = Data.get_battle_theme()
	var theme_stream = load(theme_path)
	if theme_stream:
		_battle_music.stream = theme_stream
		_battle_music.play()

	turn_order.clear()
	# 1) All players are guaranteed valid
	for p in Data.party:
		turn_order.append(p)

	# 2) Only append enemy.data if it's non-null
	for btn in _enemies_menu.get_buttons():
		if btn.data != null:
			turn_order.append(btn.data)
	current_turn_idx = 0

	_gui.show()
	_next_turn()

func _next_turn() -> void:
	print("Battle.gd/_next_turn() called")
	# —— Reset UI ——
	_options.hide()
	_menu_cursor.hide()
	_down_cursor.hide()

	# Check win/lose
	if _check_end():
		return

	var max_checks = turn_order.size()
	var checks = 0
	while checks < max_checks:
		var actor = turn_order[current_turn_idx]
		# only break if actor exists AND has HP
		if actor != null and actor.has_hp():
			break
		current_turn_idx = (current_turn_idx + 1) % turn_order.size()
		checks += 1

	# If everyone in turn_order was dead, end battle
	if checks >= max_checks:
		_end_battle(States.GAMEOVER)  # or VICTORY based on context
		return

	current_actor = turn_order[current_turn_idx]

	# Branch into player or enemy turn
	if current_actor.friendly:
		_begin_player_turn()
	else:
		_begin_enemy_turn()

func _begin_player_turn() -> void:
	print("Battle.gd/_begin_player_turn() called")
	_set_buttons_enabled(true)
	state = States.PLAYER_SELECT

	_options.show()
	_options_menu.button_focus(0)

	_menu_cursor.hide()
	_down_cursor.hide()
	
	# wait one frame before moving & showing
	await get_tree().process_frame
	
	_position_cursor_on_player(current_actor)
	_menu_cursor.show()
	_down_cursor.show()

func _on_options_button_pressed(button: BaseButton) -> void:
	print("Battle.gd/_on_options_button_pressed() called")
	$MenuCursor.play_confirm_sound()
	match button.text:
		"Fight": action = Actions.FIGHT
		"Magic": action = Actions.MAGIC
		"Item":  action = Actions.ITEM
		"Defend": action = Actions.DEFEND
	state = States.PLAYER_TARGET

	# Hide options, show enemies
	_options.hide()
	_enemies_menu.show()
	_enemies_menu.button_focus(0)
	_position_cursor_on_enemy(_enemies_menu.get_buttons()[0].data)

func _on_enemies_button_pressed(button: EnemyButton) -> void:
	print("Battle.gd/_on_options_button_pressed() called")
	$MenuCursor.play_confirm_sound()
	# Immediately hide all target‐selection UI
	_menu_cursor.hide()
	_down_cursor.hide()
	var target = button.data

	await get_tree().create_timer(0.2).timeout
	_resolve_action(current_actor, target, action)
	await get_tree().create_timer(0.8).timeout

func _begin_enemy_turn() -> void:
	_set_buttons_enabled(false)
	state = States.ENEMY_TURN
	_menu_cursor.hide()
	_down_cursor.hide()
	await get_tree().create_timer(0.5).timeout

	var target = Data.party.pick_random()
	await _resolve_action(current_actor, target, Actions.FIGHT)

func _resolve_action(actor: BattleActor, target: BattleActor, act: Actions) -> void:
	print("Battle.gd/_resolve_action() called")
	# block every button and early-out guards
	_set_buttons_enabled(false)
	_menu_cursor.hide()
	
	if not actor.can_act() or not target.has_hp():
		return
		
	# 1) Slide actor in
	var actor_btn = _get_button_for_actor(actor)
	if actor_btn:
		var tween_slide = actor_btn.action_slide()
		await tween_slide.finished
		
	# 2) Apply effect
	match act:
		Actions.FIGHT:
			var dmg = actor.strength
			target.healhurt(-dmg)
			_log_action("%s attacks %s for %d damage!" % [actor.name, target.name, dmg])
			# 3) Recoil on target
			var target_btn = _get_button_for_actor(target)
			if target_btn:
				var tween_hit = target_btn.recoil()
				await tween_hit.finished
			# remove from turn_order if they dropped to 0 hp
			if not target.has_hp():
				var idx = turn_order.find(target)
				if idx != -1:
					# if the dead one was before our current pointer, shift back
					if idx < current_turn_idx:
						current_turn_idx -= 1
					turn_order.remove_at(idx)
		Actions.MAGIC:
			# Implement magic logic
			_log_action("%s casts a spell!" % actor.name)
		Actions.ITEM:
			# Implement item logic
			_log_action("%s uses an item!" % actor.name)
		Actions.DEFEND:
			_log_action("%s defends!" % actor.name)
		_:
			pass
	# once all animations and death‐pruning are done
	await get_tree().create_timer(0.2).timeout
	# Unblock them again for the next turn
	_set_buttons_enabled(true)
	_advance_index()
	_next_turn()

func _advance_index() -> void:
	print("Battle.gd/_advance_index() called")
	if turn_order.size() == 0:
		return
	current_turn_idx = (current_turn_idx + 1) % turn_order.size()

func _check_end() -> bool:
	print("Battle.gd/_check_end() called")
	var any_player_alive = false
	for p in Data.party:
		if p.has_hp():
			any_player_alive = true
			break

	var any_enemy_alive = false
	for btn in _enemies_menu.get_buttons():
		# Only call has_hp() if data is set
		var actor = btn.data
		if actor != null and actor.has_hp():
			any_enemy_alive = true
			break

	if not any_enemy_alive:
		_end_battle(States.VICTORY)
		return true
	elif not any_player_alive:
		_end_battle(States.GAMEOVER)
		return true

	return false

func _end_battle(result_state: States) -> void:
	print("Battle.gd/_end_battle() called")
	state = result_state
	_options.hide()
	_enemies_menu.hide()
	_menu_cursor.hide()

	# Delay to let final logs/FX complete
	await get_tree().create_timer(1.0).timeout

	match state:
		States.VICTORY:
			var victory_music = load(Data.victory_theme)
			if victory_music:
				_battle_music.stream = victory_music
				_battle_music.play()
			print("YOU WON!")
		States.GAMEOVER:
			var gameover_music = load(Data.gameover_theme)
			if gameover_music:
				_battle_music.stream = gameover_music
				_battle_music.play()
			print("YOU LOSE!")

	# Hide battle UI, return to map, etc.
	_gui.hide()

func _position_cursor_on_player(actor: BattleActor) -> void:
	var idx = Data.party.find(actor)
	var btn = _players_menu.get_buttons()[idx]
	_menu_cursor.global_position = btn.global_position
	_down_cursor.global_position = btn.global_position + Vector2(5, -10)
	_down_cursor.show()

func _position_cursor_on_enemy(enemy: BattleActor) -> void:
	# give Godot one frame to size/position all the new labels
	await get_tree().process_frame

	# find the matching Label in our cached array
	for lbl in _enemy_info_nodes:
		if lbl.get_meta("actor") == enemy:
			# this one line scrolls it into view:
			_enemy_info_scroll.ensure_control_visible(lbl)
			return

func _position_cursor_off() -> void:
	_down_cursor.hide()
	_menu_cursor.hide()

func _cancel_target_selection() -> void:
	state = States.PLAYER_SELECT

	_down_cursor.hide()

	_options.show()
	_menu_cursor.show()
	_options_menu.button_focus()
	_position_cursor_on_player(current_actor)

func _get_button_for_actor(actor: BattleActor) -> BattleActorButton:
	for btn in _players_menu.get_buttons():
		if btn.data == actor:
			return btn
	for btn in _enemies_menu.get_buttons():
		if btn.data == actor:
			return btn
	return null

func _spawn_random_enemies(requested_count: int) -> void:
	var actors = Data.get_random_enemies(requested_count)

	for i in range(_enemy_slots.size()):
		var slot = _enemy_slots[i]
		slot.focus_mode = Control.FOCUS_ALL
		slot.connect("focus_entered",Callable(self, "_on_enemy_button_focused").bind(slot))
		if i < actors.size():
			slot.show()
			slot.set_data(actors[i])
		else:
			slot.hide()
			#slot.set_data(null)  # optional, clears old data
	_reload_enemy_info(actors)

func _slide_group(buttons: Array, duration: float):
	# Moves a group of buttons from their current (off-screen) positionsback to _orig_positions over 'duration' seconds.
	var elapsed := 0.0
	while elapsed < duration:
		var t = elapsed / duration
		for btn in buttons:
			btn.position = btn.position.lerp(_orig_positions[btn], t)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	# Snap to final
	for btn in buttons:
		btn.position = _orig_positions[btn]

func get_buttons() -> Array:
	return get_children().filter(func(c):
		return c is EnemyButton and c.visible and c.data != null)

func _get_enemy_slots() -> Array:
	return _enemy_info_vbox.get_children().filter(func(c):
		return c is EnemyButton)

func _reload_enemy_info(actors: Array) -> void:
	# Clear out old labels
	for child in _enemy_info_vbox.get_children():
		child.queue_free()
	_enemy_info_nodes.clear()

	# Create one Label per actor & cache it
	for actor in actors:
		var lbl = Label.new()
		lbl.text = actor.name
		lbl.set_meta("actor", actor)
		_enemy_info_vbox.add_child(lbl)
		_enemy_info_nodes.append(lbl)

		# remove it when that actor dies
		actor.defeated.connect(func() -> void:
			_on_enemy_defeated(actor))

	# Reset scroll to top
	_enemy_info_scroll.scroll_vertical = 0

func _on_enemy_defeated(enemy: BattleActor) -> void:
	for i in range(_enemy_info_nodes.size()-1, -1, -1):
		if _enemy_info_nodes[i].get_meta("actor") == enemy:
			_enemy_info_nodes[i].queue_free()
			_enemy_info_nodes.remove_at(i)
			break

func _on_enemy_button_focused(button: EnemyButton) -> void:
	var actor = button.data
	_highlight_and_scroll_info(actor)

func _highlight_and_scroll_info(actor: BattleActor) -> void:
	# 1) Highlight the matching Label, dim the rest
	for lbl in _enemy_info_nodes:
		var is_target = lbl.get_meta("actor") == actor
		lbl.self_modulate = Color(1,1,1) if is_target else Color(0.5,0.5,0.5)

	# 2) Wait one frame for the VBox layout to settle
	await get_tree().process_frame

	# 3) Bring the focused label into view
	for lbl in _enemy_info_nodes:
		if lbl.get_meta("actor") == actor:
			_enemy_info_scroll.ensure_control_visible(lbl)
			return

func _set_buttons_enabled(enabled: bool) -> void:
	# 1) your Option buttons (those are BaseButtons inside your WindowDefault)
	for child in $Options.get_children():
		if child is BaseButton:
			child.disabled = not enabled

	# 2) your enemy‐target buttons
	for btn in _enemies_menu.get_buttons():
		btn.disabled = not enabled

	# 3) your player‐select buttons
	for btn in _players_menu.get_buttons():
		btn.disabled = not enabled

	# 4) if you ever use PopupMenu (the Menu node) for keyboard shortcuts,
	#    you can disable menu items by index:
	# for i in range(_options_menu.get_item_count()):
	#     _options_menu.set_item_disabled(i, not enabled)
