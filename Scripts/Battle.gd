extends Control
class_name Battle

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

# UI nodes
@onready var _top_cover = $CanvasLayer/TopCover
@onready var _bottom_cover = $CanvasLayer/BottomCover
@onready var _battle_music: AudioStreamPlayer = $BattleMusic
@onready var _log_label: Label = $ActionLogLabel
@onready var _gui: Control = $GUIMargin
@onready var _options: WindowDefault = $Options
@onready var _options_menu: Menu = $Options/Options
@onready var _enemies_menu: Menu = $Enemies
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
	# 1) Point directly at the intro theme
	var theme_path = Data.intro_theme

	# 2) Load and play
	var theme_stream = load(theme_path)
	if theme_stream:
		_battle_music.stream = theme_stream
		_battle_music.play()
	
	
	_stash_and_offset_buttons()
	
	## Intro Animation
	await get_tree().create_timer(0.5).timeout

	# 1) Slide players
	await _slide_group(_players_menu.get_buttons(), 0.3)

	# Optional pause
	await get_tree().create_timer(1.0).timeout

	# 2) Slide enemies
	await _slide_group(_enemies_menu.get_buttons(), 0.6)

	# 3) Start the battle
	_start_battle()

func _start_battle() -> void:
	# Play battle theme
	var theme_path = Data.get_battle_theme()
	var theme_stream = load(theme_path)
	if theme_stream:
		_battle_music.stream = theme_stream
		_battle_music.play()

	# Build turn order: all players first, then enemies
	turn_order.clear()
	for p in Data.party:
		turn_order.append(p)
	for enemy_btn in _enemies_menu.get_buttons():
		turn_order.append(enemy_btn.data)

	current_turn_idx = 0
	_gui.show()
	_next_turn()

func _next_turn() -> void:
	# —— Reset UI ——
	_options.hide()
	_menu_cursor.hide()
	_down_cursor.hide()

	# Check win/lose
	if _check_end():
		return

	# Skip over any defeated actors
	var max_checks = turn_order.size()
	var checks = 0
	while checks < max_checks and not turn_order[current_turn_idx].has_hp():
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
	_menu_cursor.show()
	_enemies_menu.button_focus(0)
	_position_cursor_on_enemy(_enemies_menu.get_buttons()[0].data)

func _on_enemies_button_pressed(button: EnemyButton) -> void:
	$MenuCursor.play_confirm_sound()
	var target = button.data

	# Immediately hide all target‐selection UI
	_menu_cursor.hide()
	_down_cursor.hide()

	await get_tree().create_timer(0.2).timeout
	_resolve_action(current_actor, target, action)
	await get_tree().create_timer(0.8).timeout

func _begin_enemy_turn() -> void:
	state = States.ENEMY_TURN
	_menu_cursor.hide()
	_down_cursor.hide()
	await get_tree().create_timer(0.5).timeout

	var target = Data.party.pick_random()
	await _resolve_action(current_actor, target, Actions.FIGHT)
	# <-- NOTHING else here!

func _resolve_action(actor: BattleActor, target: BattleActor, act: Actions) -> void:
	print("Battle.gd/_resolve_action() called")
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
	_advance_index()
	_next_turn()

func _log_action(text: String) -> void:
	action_log.append(text)
	if action_log.size() > MAX_LOG_LINES:
		action_log.pop_front()
	_log_label.text = "\n".join(action_log)

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
		if btn.data.has_hp():
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
	for btn in _enemies_menu.get_buttons():
		if btn.data == enemy:
			_menu_cursor.global_position = btn.global_position
			#_down_cursor.global_position = btn.global_position + Vector2(5, -10)
			#_down_cursor.show()
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

# Moves a group of buttons from their current (off-screen) positionsback to _orig_positions over 'duration' seconds.
func _slide_group(buttons: Array, duration: float):
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
