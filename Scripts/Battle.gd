class_name Battle extends Control

# Enums for battle states and player actions
enum States { INTRO, IDLE, PLAYER_SELECT, PLAYER_TARGET, ENEMY_TURN, VICTORY, GAMEOVER }
enum Actions { FIGHT, SKILLS, ITEM, DEFEND }

# Exports
@export var transition_time       :                   = 0.7

# Onready variables for UI and game elements
@onready var _battle_music        :AudioStreamPlayer  = $BattleMusic
@onready var _log_label           :Label              = $ActionLogLabel
@onready var _gui                 :Control            = $GUIMargin
@onready var _options             :WindowDefault      = $Options
@onready var _options_menu        :Menu               = $Options/Options
@onready var _enemies_menu        :Menu               = $Enemies
@onready var _enemy_slots         :                   = $Enemies.get_children()
@onready var _enemy_info_scroll   :ScrollContainer    = $GUIMargin/Bottom/Enemies/ScrollContainer
@onready var _enemy_info_vbox     :VBoxContainer      = _enemy_info_scroll.get_node("MarginContainer/VBoxContainer")
@onready var _players_menu        :Menu               = $Players
@onready var _menu_cursor         :MenuCursor         = $MenuCursor
@onready var _down_cursor         :Sprite2D           = $DownCursor

# Constants
const MAX_LOG_LINES               :                   = 3

# Variables to track battle state and flow
var input_locked                  :bool               = false
var state                         :States             = States.IDLE
var _orig_positions               :                   = {}
var turn_order                    :Array[BattleActor] = []
var current_turn_idx              :int                = 0
var current_actor                 :BattleActor        = null
var action                        :Actions            = Actions.FIGHT
var action_log                    :Array[String]      = []
var EnemyButtonScene              :PackedScene        = preload("res://scenes/EnemyButton.tscn")
var _enemy_info_nodes             :Array[Label]       = []

# Called when the scene is ready
func _ready():
	_options.hide()
	_down_cursor.hide()
	_gui.hide()
	call_deferred("_play_intro")  # Defer so _ready finishes first

# Handles global input events (like canceling target selection)
func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		get_viewport().gui_disable_input = true
		return
	if event.is_action_pressed("ui_cancel") and state == States.PLAYER_TARGET:
		_cancel_target_selection()

# Adds a line to the battle log, maintaining max line count
func _log_action(text: String) -> void:
	action_log.append(text)
	if action_log.size() > MAX_LOG_LINES:
		action_log.pop_front()
	_log_label.text = "\n".join(action_log)

# Stores original button positions and offsets them for intro animation
func _stash_and_offset_buttons() -> void:
	print("Battle.gd/_stash_and_offset_buttons() called")
	var screen_w = get_viewport_rect().size.x

	# Players slide in from left
	for btn in _players_menu.get_buttons():
		_orig_positions[btn] = btn.position
		btn.position.x += screen_w

	# Enemies slide in from right
	for btn in _enemies_menu.get_buttons():
		_orig_positions[btn] = btn.position
		btn.position.x -= screen_w

# Handles the intro sequence (spawning enemies, music, animations)
func _play_intro() -> void:
	print("Battle.gd/_play_intro() called")
	state = States.INTRO
	set_process_input(false)

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

	# 4) Show the UI and start the turn loop
	_gui.show()
	_start_battle()

# Begins the main battle loop, sets turn order, starts first turn
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

# Advances to the next turn, handling dead actors and end conditions
func _next_turn() -> void:
	print("Battle.gd/_next_turn() called")
	# Reset UI
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

# Handles player turn setup (enabling UI, setting focus, showing options)
func _begin_player_turn() -> void:
	print("Battle.gd/_begin_player_turn() called")
	_set_buttons_enabled(true)
	set_process_input(true)
	state = States.PLAYER_SELECT

	_options.show()
	_options_menu.button_enable_focus(true)           # Enable focus on options
	_enemies_menu.button_enable_focus(false)          # Disable focus on enemies
	_players_menu.button_enable_focus(false)          # Disable focus on players

	_options_menu.button_focus(0)
	_down_cursor.hide()
	await get_tree().process_frame
	_position_cursor_on_player(current_actor)

# Handles when a player chooses a battle option (Fight/Skills/Item/Defend)
func _on_options_button_pressed(button: BaseButton) -> void:
	print("Battle.gd/_on_options_button_pressed() called")
	$MenuCursor.play_confirm_sound()
	match button.text:
		"Fight": action = Actions.FIGHT
		"Skills": action = Actions.SKILLS
		"Item":  action = Actions.ITEM
		"Defend": action = Actions.DEFEND
	state = States.PLAYER_TARGET

	_options.hide()
	_enemies_menu.show()
	_enemies_menu.button_enable_focus(true)          # Enable focus on enemies
	_players_menu.button_enable_focus(false)
	_options_menu.button_enable_focus(false)

	_enemies_menu.button_focus(0)
	_position_cursor_on_enemy(_enemies_menu.get_buttons()[0].data)

# Handles when player selects an enemy to target
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

# Handles enemy turn logic (picking a target, resolving action)
func _begin_enemy_turn() -> void:
	print("Battle.gd/_begin_enemy_turn() called")
	_set_buttons_enabled(false)
	set_process_input(false)
	state = States.ENEMY_TURN
	_menu_cursor.hide()
	_down_cursor.hide()

	var target = _pick_random_alive_party_member()
	if target == null:
		# All players are dead, end battle
		_end_battle(States.GAMEOVER)
		return
	await _resolve_action(current_actor, target, Actions.FIGHT)

# Resolves the chosen action for current actor (attack, skill, item, defend)
func _resolve_action(actor: BattleActor, target: BattleActor, act: Actions) -> void:
	print("Battle.gd/_resolve_action() called")
	_set_buttons_enabled(false)
	_menu_cursor.hide()

	if not actor.can_act() or not target.has_hp():
		return

	# grab the UI buttons for both participants
	var actor_btn  = _get_button_for_actor(actor)  as BattleActorButton
	var target_btn = _get_button_for_actor(target) as BattleActorButton

	if not actor_btn or not target_btn:
		push_error("Couldn’t find UI button for actor or target")
		return

	match act:
		Actions.FIGHT:
			# CALL _attack() and wait for it to finish
			await actor_btn._attack(target_btn)
			# Log after the attack sequence completes
			_log_action("%s attacks %s for %d damage!" % [actor.name, target.name, actor.strength])

			# If target just died, remove from turn order
			if not target.has_hp():
				var idx = turn_order.find(target)
				if idx >= 0:
					if idx < current_turn_idx:
						current_turn_idx -= 1
					turn_order.remove_at(idx)

		Actions.SKILLS:
			_log_action("%s casts a spell!" % actor.name)
			# your skill logic here…

		Actions.ITEM:
			_log_action("%s uses an item!" % actor.name)
			# your item logic…

		Actions.DEFEND:
			_log_action("%s defends!" % actor.name)
			# your defend logic…

		_:
			pass

	# small delay, then next turn
	await get_tree().create_timer(0.5).timeout
	_set_buttons_enabled(true)
	_advance_index()
	_next_turn()

# Moves to the next actor in the turn order
func _advance_index() -> void:
	print("Battle.gd/_advance_index() called")
	if turn_order.size() == 0:
		return
	current_turn_idx = (current_turn_idx + 1) % turn_order.size()

# Checks if the battle should end (victory/defeat), returns true if so
func _check_end() -> bool:
	print("Battle.gd/_check_end() called")
	set_process_input(false)
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

# Handles end-of-battle logic and transitions (music, UI, etc)
func _end_battle(result_state: States) -> void:
	print("Battle.gd/_end_battle() called")
	set_process_input(true)
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

# Moves the cursor to the currently active player button
func _position_cursor_on_player(actor: BattleActor) -> void:
	print("Battle.gd/_position_cursor_on_player() called")
	var idx = Data.party.find(actor)
	var btn = _players_menu.get_buttons()[idx]
	
	_menu_cursor.global_position = btn.global_position
	_down_cursor.global_position = btn.global_position + Vector2(5, -10)
	_down_cursor.show()

# Moves the cursor and scrolls to the selected enemy info label
func _position_cursor_on_enemy(enemy: BattleActor) -> void:
	print("Battle.gd/_position_cursor_on_enemy() called")
	# Find the matching Label in cached array
	for lbl in _enemy_info_nodes:
		if lbl.get_meta("actor") == enemy:
			# Scroll it into view:
			_enemy_info_scroll.ensure_control_visible(lbl)
			return

# Hides both cursors from view
func _position_cursor_off() -> void:
	print("Battle.gd/_position_cursor_off() called")
	_down_cursor.hide()
	_menu_cursor.hide()

# Cancels target selection, returns to options menu
func _cancel_target_selection() -> void:
	print("Battle.gd/_cancel_target_selection() called")
	state = States.PLAYER_SELECT
	_down_cursor.hide()
	_options.show()
	_options_menu.button_enable_focus(true)          # Re-enable options focus
	_enemies_menu.button_enable_focus(false)
	_players_menu.button_enable_focus(false)

	_menu_cursor.show()
	_options_menu.button_focus()
	_position_cursor_on_player(current_actor)

# Finds the button associated with a given actor (player or enemy)
func _get_button_for_actor(actor: BattleActor) -> BattleActorButton:
	print("Battle.gd/_get_button_for_actor() called")
	for btn in _players_menu.get_buttons():
		if btn.data == actor:
			return btn
	for btn in _enemies_menu.get_buttons():
		if btn.data == actor:
			return btn
	return null

# Spawns a requested number of random enemies and sets up their UI
func _spawn_random_enemies(requested_count: int) -> void:
	print("Battle.gd/_spawn_random_enemies() called")
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

# Slides a group of buttons back to their starting positions
func _slide_group(buttons: Array, duration: float):
	# Moves the group of buttons from their current (off-screen) positions back to _orig_positions over 'duration' seconds.
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

# Returns all visible, valid enemy buttons
func get_buttons() -> Array:
	return get_children().filter(func(c):
		return c is EnemyButton and c.visible and c.data != null)

# Returns all enemy slots in the info VBox
func _get_enemy_slots() -> Array:
	return _enemy_info_vbox.get_children().filter(func(c):
		return c is EnemyButton)

# Rebuilds the enemy info sidebar for currently active enemies
func _reload_enemy_info(actors: Array) -> void:
	# Clear old labels
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

		# Remove Label when actor dies
		actor.defeated.connect(func() -> void:
			_on_enemy_defeated(actor))

	# Reset scroll to top
	_enemy_info_scroll.scroll_vertical = 0

# Removes enemy labels when defeated
func _on_enemy_defeated(enemy: BattleActor) -> void:
	for i in range(_enemy_info_nodes.size()-1, -1, -1):
		if _enemy_info_nodes[i].get_meta("actor") == enemy:
			_enemy_info_nodes[i].queue_free()
			_enemy_info_nodes.remove_at(i)
			break

# Highlights and scrolls to enemy info when their button is focused
func _on_enemy_button_focused(button: EnemyButton) -> void:
	var actor = button.data
	_highlight_and_scroll_info(actor)

# Highlights selected enemy and dims others; scrolls to selected enemy
func _highlight_and_scroll_info(actor: BattleActor) -> void:
	#Highlight the matching Label, dim the rest
	for lbl in _enemy_info_nodes:
		var is_target = lbl.get_meta("actor") == actor
		lbl.self_modulate = Color(1,1,1) if is_target else Color(0.5,0.5,0.5)

	#Wait one frame for VBox layout to settle
	await get_tree().process_frame

	#Bring the focused label into view
	for lbl in _enemy_info_nodes:
		if lbl.get_meta("actor") == actor:
			_enemy_info_scroll.ensure_control_visible(lbl)
			return

# Enables or disables all player and enemy buttons, also disables process_input
func _set_buttons_enabled(enabled: bool) -> void:
	print("Battle.gd/_set_buttons_enabled() called")
	# Option buttons (BaseButtons inside WindowDefault)
	for child in $Options.get_children():
		if child is BaseButton:
			child.disabled = not enabled
		child.set_process_input(enabled)

	# Enemy buttons
	for btn in _enemies_menu.get_buttons():
		btn.disabled = not enabled
		btn.set_process_input(enabled)

	# Player buttons
	for btn in _players_menu.get_buttons():
		btn.disabled = not enabled
		btn.set_process_input(enabled)

# Returns a random alive party member for enemy targeting
func _pick_random_alive_party_member() -> BattleActor:
	var alive = Data.party.filter(func(p): return p.has_hp())
	if alive.size() == 0:
		return null
	return Util.choose(alive)
