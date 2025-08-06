class_name StartCursor extends TextureRect

@export var menu_root_path : NodePath

# Node and sound references
@onready var menu_root = get_node(menu_root_path) if menu_root_path else null
@onready var move_sound :AudioStreamPlayer = $MoveSound
@onready var confirm_sound :AudioStreamPlayer = $ConfirmSound

const OFFSET :Vector2 = Vector2(-18, -2) # Cursor offset from target

var hide_timer : Timer = null
var target :Node = null

# Setup signals, timer, and hide on start
func _ready():
	get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)
	set_process(false)
	hide()
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.wait_time = 1.0 # Cursor hide delay
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(hide_timer)

# Move cursor to target each frame
func _process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		hide()
		set_process(false)
		return
	global_position = target.global_position + OFFSET

# Handle GUI focus changes
func _on_viewport_gui_focus_changed(node: Control):
	call_deferred("_deferred_focus_change", node)
	if node is BaseButton:
		if hide_timer.is_stopped() == false:
			hide_timer.stop()
		if target != node and move_sound.stream:
			move_sound.play()
		if target and target.is_connected("tree_exiting", Callable(self, "_on_target_tree_exiting")):
			target.disconnect("tree_exiting", Callable(self, "_on_target_tree_exiting"))
		target = node
		if not target.is_connected("tree_exiting", Callable(self, "_on_target_tree_exiting")):
			target.connect("tree_exiting", Callable(self, "_on_target_tree_exiting"))
		show()
		set_process(true)
	else:
		if menu_root and menu_root.has_method("is_repopulating") and menu_root.is_repopulating:
			return # Ignore hiding during shop repopulation
		hide_timer.start()
		set_process(false)

# Stop tracking if target is removed
func _on_target_tree_exiting():
	target = null
	set_process(false)

# Play confirmation sound
func play_confirm_sound():
	if confirm_sound.stream:
		confirm_sound.play()

# Handle deferred focus changes
func _deferred_focus_change(node: Control) -> void:
	if node is BaseButton and node.visible:
		_set_target(node)
	else:
		hide()
		set_process(false)

# Update target and cursor position
func _set_target(node: Control) -> void:
	if target and target.is_connected("tree_exiting", Callable(self, "_on_target_tree_exiting")):
		target.disconnect("tree_exiting", Callable(self, "_on_target_tree_exiting"))
	target = node
	if not target.is_connected("tree_exiting", Callable(self, "_on_target_tree_exiting")):
		target.connect("tree_exiting", Callable(self, "_on_target_tree_exiting"))
	global_position = target.global_position + OFFSET
	show()
	set_process(true)
	if move_sound.stream:
		move_sound.play()

# Hide cursor when timer runs out
func _on_hide_timer_timeout():
	hide()
