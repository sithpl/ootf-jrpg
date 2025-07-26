class_name ShopCursor extends TextureRect

@export var shop_path :NodePath   # Path to ShopUI node (optional)

@onready var shop :ShopUI = $".."
@onready var move_sound :AudioStreamPlayer = $MoveSound
@onready var confirm_sound :AudioStreamPlayer = $ConfirmSound

const OFFSET :Vector2 = Vector2(-18, -2)

var target :Node = null

func _ready():
	get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)
	set_process(false)
	hide()

func _process(_delta: float) -> void:
	#DEBUG print("ShopCursor processing, target: ", target)
	if target == null or not is_instance_valid(target):
		hide()
		set_process(false)
		return
	global_position = target.global_position + OFFSET

func _on_viewport_gui_focus_changed(node: Control):
	#DEBUG print("Focus changed to: ", node)
	call_deferred("_deferred_focus_change", node)
	if node is BaseButton:
		if target != node and move_sound.stream:
			move_sound.play()
		if target and target.tree_exiting.is_connected(_on_target_tree_exiting):
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
	if node is BaseButton and node.visible:
		_set_target(node)
	else:
		hide()
		set_process(false)

func _set_target(node: Control) -> void:
	if target and target.tree_exiting.is_connected(_on_target_tree_exiting):
		target.tree_exiting.disconnect(_on_target_tree_exiting)
	target = node
	target.tree_exiting.connect(_on_target_tree_exiting)
	global_position = target.global_position + OFFSET
	show()
	set_process(true)
	if move_sound.stream:
		move_sound.play()
