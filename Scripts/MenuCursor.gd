class_name MenuCursor extends TextureRect

const OFFSET: Vector2 = Vector2(-18, -2)

@export var battle_path : NodePath

var target: Node = null

@onready var battle : Battle = $".."
@onready var move_sound: AudioStreamPlayer = $MoveSound
@onready var confirm_sound: AudioStreamPlayer = $ConfirmSound

func _ready():
	get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)
	set_process(false)
	hide()

func _process(_delta: float) -> void:
	# if target has been freed (or was never set), bail out immediately
	if target == null or not is_instance_valid(target):
		hide()
		set_process(false)
		return

	# safe to access now
	global_position = target.global_position + OFFSET

func _on_viewport_gui_focus_changed(node: Control):
	call_deferred("_deferred_focus_change", node)
	if node is BaseButton:
		if target != node:
			if move_sound.stream:
				move_sound.play()
		if target:
			target.tree_exiting.disconnect(_on_target_tree_exiting)

		target = node
		target.tree_exiting.connect(_on_target_tree_exiting.bind(target))
		show()
		set_process(true)
	else:
		hide()
		set_process(false)

func _on_target_tree_exiting(node: Control):
	if node == target:
		target = null
		set_process(false)

func play_confirm_sound():
	if confirm_sound.stream:
		confirm_sound.play()

func _deferred_focus_change(node: Control) -> void:
	# only show when Battle is in the correct state
	if node is BaseButton and battle.state in [
			battle.States.PLAYER_SELECT,
			battle.States.PLAYER_TARGET
		]:
		_set_target(node)
	else:
		hide()
		set_process(false)
		
func _set_target(node: Control) -> void:
	# disconnect old target
	if target:
		target.tree_exiting.disconnect(_on_target_tree_exiting)
	# assign & connect new
	target = node
	target.tree_exiting.connect(_on_target_tree_exiting)
	# position & show
	global_position = target.global_position + OFFSET
	show()
	set_process(true)
	if move_sound.stream:
		move_sound.play()
