class_name Battle extends Control

enum States {
	OPTIONS,
	TARGETS,
	VICTORY,
	GAMEOVER,
}

enum Actions {
	FIGHT,
}

enum {
	ACTOR,
	TARGET,
	ACTION,
}

const MAX_LOG_LINES := 3

var state: States = States.OPTIONS
var player_atb_queue: Array = []
var event_queue: Array = []
var event_running: bool = false
var action: Actions = Actions.FIGHT
var player: BattleActor = null
var action_log: Array[String] = []

@onready var _log_label: Label = $ActionLogLabel
@onready var _gui: Control = $GUIMargin
@onready var _options: WindowDefault = $Options
@onready var _options_menu: Menu = $Options/Options
@onready var _enemies_menu: Menu = $Enemies
@onready var _players_menu: Menu = $Players
@onready var _players_infos: Array = $GUIMargin/Bottom/Players/MarginContainer/PlayerInfos.get_children()
@onready var _menu_cursor: MenuCursor = $MenuCursor
@onready var _down_cursor: Sprite2D = $DownCursor

func _ready():
	_options.hide()
	_down_cursor.hide()
	
	# Connect players and enemies
	var data: BattleActor = null
	for player_info in _players_infos:
		data = player_info.data
		player_info.atb_ready.connect(_on_player_atb_ready.bind(player_info))
		data.defeated.connect(_on_battle_actor_defeated.bind(data))
	
	for enemy_button in _enemies_menu.get_buttons():
		data = enemy_button.data
		enemy_button.atb_ready.connect(_on_enemy_atb_ready.bind(data))
		data.defeated.connect(_on_battle_actor_defeated.bind(data))

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		match state:
			States.OPTIONS:
				pass
			States.TARGETS:
				state = States.OPTIONS
				_options_menu.button_focus()

#func add_actor_to_atb_queue(actor: TextureButton):
	#if player_atb_queue.is_empty():
		#actor.highlight()

func find_valid_target(target: BattleActor):
	if target.has_hp():
		return target
	
	var target_buttons: Array = []
	var target_is_friendly: bool = target.friendly
	if target_is_friendly:
		target_buttons = _players_menu.get_buttons()
	else:
		target_buttons = _enemies_menu.get_buttons()
	
	target = null
	target_buttons.shuffle()
	for i in range(target_buttons.size()):
		var button: BattleActorButton = target_buttons[i]
		var data: BattleActor = button.data
		if data.has_hp():
			target = data
			break
	
	if target == null:
		state = States.GAMEOVER if target_is_friendly else States.VICTORY
	
	return target

func end():
	event_queue.clear()
	player_atb_queue.clear()
	_menu_cursor.hide()
	_down_cursor.hide()
	_options.hide()
	await get_tree().create_timer(1.0)
	_gui.hide()
	
	for player_info in _players_infos:
		player_info.highlight(true)
		player_info.reset()
		player_info.stop()
		
	# TODO Actual battle end states
	match state:
		States.VICTORY:
			print("WTF YOU WON???")
		States.GAMEOVER:
			print("YOU LOSE STUPID BITCH")

func log_action(text: String) -> void:
	action_log.append(text)
	if action_log.size() > MAX_LOG_LINES:
		action_log.pop_front()
	_log_label.text = "\n".join(action_log)

func advance_atb_queue(remove_front: bool = true):
	if state >= States.VICTORY:
		return
	state = States.OPTIONS
	
	if player_atb_queue.is_empty():
		return
	
	if remove_front:
		var current_player_info_bar: PlayerInfoBar = player_atb_queue.pop_front()
		current_player_info_bar.highlight(false)
	
	if player_atb_queue.is_empty():
		get_viewport().gui_release_focus()
		_options.hide()
		_menu_cursor.hide()
		_down_cursor.hide()
	else:
		var next_player_info_bar: PlayerInfoBar = player_atb_queue.front()
		var index: int = next_player_info_bar.get_index()
		next_player_info_bar.highlight()
		player = Data.party[index]
		_options.show()
		_options_menu.button_focus(0)
		_down_cursor.show()
		_down_cursor.global_position = _players_menu.get_buttons()[index].global_position + Vector2(8, -10)

#func wait(duration: float):
	#await get_tree().create_timer(duration).timeout

func run_event():
	if event_queue.is_empty():
		event_running = false
		return
	
	event_running = true
	await get_tree().create_timer(0.5).timeout
	
	if state >= States.VICTORY:
		return
	
	var event: Array = event_queue.pop_front()
	var actor: BattleActor = event[ACTOR]
	var target: BattleActor = event[TARGET]
	
	# Skip event if actor can no longer act
	if !actor.can_act():
		run_event()
	
	# Ensure target is valid
	var target_is_friendly: bool = Data.party.has(target)
	target = find_valid_target(target)
	
	# No valid targets. One side has won!
	if target == null:
		end()
		
		return
	
	# Perform action
	actor.act()
	await get_tree().create_timer(0.25).timeout
	match event[ACTION]:
		Actions.FIGHT:
			target.healhurt(-actor.strength)
			log_action("%s attacks %s for %d damage!" % [actor.name, target.name, actor.strength])
		_:
			pass
	
	#await wait(0.75)
	await get_tree().create_timer(1.25).timeout
	if actor.friendly:
		_players_infos[Data.party.find(actor)].reset()
		advance_atb_queue()
	else:
		var enemies: Array = _enemies_menu.get_children()
		for enemy in enemies:
			if enemy.data == actor:
				enemy.reset()
				break
	
	run_event()

func add_event(event: Array):
	event_queue.append(event)
	if !event_running:
		run_event()

#func _on_options_button_focused(button: BaseButton) -> void:
	#pass

func _on_options_button_pressed(button: BaseButton) -> void:
	#DEBUG print(button.text)
	match button.text:
		"Fight":
			action = Actions.FIGHT
			state = States.TARGETS
			_enemies_menu.button_focus()

func _on_player_atb_ready(player_info: PlayerInfoBar):
	player_atb_queue.append(player_info)
	if player_atb_queue.size() == 1:
		advance_atb_queue(false)

func _on_enemy_atb_ready(enemy: BattleActor):
	var target: BattleActor = Data.party.pick_random()
	#DEBUG print(target)
	add_event([enemy, target, Actions.FIGHT]) # TODO choosing action

func _on_enemies_button_pressed(button: EnemyButton) -> void:
	var target: BattleActor = button.data
	add_event([player, target, action])
	#DEBUG print(target, action)
	advance_atb_queue()

func _on_players_button_pressed(button: PlayerButton) -> void:
	var target: BattleActor = button.data
	event_queue.append([player, action])
	#DEBUG print(player, target, action)
	advance_atb_queue()

func _on_battle_actor_defeated(data: BattleActor):
	if !find_valid_target(data):
		end()
	
	var player_index: int = Data.party.find(data)
	if player_index != -1:
		var player_info: PlayerInfoBar = _players_infos[player_index]
		player_atb_queue.erase(player_info)
