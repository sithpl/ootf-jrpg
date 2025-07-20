class_name MenuCursor extends TextureRect

# Exports
@export var battle_path   :NodePath   # Path to Battle node (optional)

# Onreadys
@onready var battle          :Battle              = $".."         # Reference to Battle node (assumes parent)
@onready var move_sound      :AudioStreamPlayer   = $MoveSound
@onready var confirm_sound   :AudioStreamPlayer   = $ConfirmSound

# Constants
const OFFSET   :Vector2   = Vector2(-18, -2)   # Offset for cursor position relative to target button

# Variables
var target   :Node   = null   # The currently focused button

# Called when node enters the scene tree
func _ready():
	get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)
	set_process(false)
	hide()

# Continuously updates cursor position to match target (if any)
func _process(_delta: float) -> void:
	# If target has been freed or never set, hide and stop processing
	if target == null or not is_instance_valid(target):
		hide()
		set_process(false)
		return

	# Safe to access now; position cursor at target + offset
	global_position = target.global_position + OFFSET

# Handles global focus changes in the viewport (when a button is focused/unfocused)
func _on_viewport_gui_focus_changed(node: Control):
	print("MenuCursor.gd/_on_viewport_gui_focus_changed() called")
	call_deferred("_deferred_focus_change", node)
	if node is BaseButton:
		# Play move sound if target changes
		if target != node:
			if move_sound.stream:
				move_sound.play()
		# Disconnect old target's exiting signal
		if target:
			target.tree_exiting.disconnect(_on_target_tree_exiting)

		target = node
		target.tree_exiting.connect(_on_target_tree_exiting.bind(target))
		show()
		set_process(true)
	else:
		hide()
		set_process(false)

# Handles when the current target button is removed from the scene
func _on_target_tree_exiting(node: Control):
	print("MenuCursor.gd/_on_target_tree_exiting() called")
	if node == target:
		target = null
		set_process(false)

# Play confirmation sound (used when selecting an option)
func play_confirm_sound():
	if confirm_sound.stream:
		confirm_sound.play()

# Handles deferred logic for focus change (waits a frame for menu visibility)
func _deferred_focus_change(node: Control) -> void:
	print("MenuCursor.gd/_deferred_focus_change() called")
	# Only show when Battle is in the correct state AND the menu is visible
	var menu_is_visible = false
	if battle.state == battle.States.PLAYER_SELECT:
		menu_is_visible = battle._options.visible
	elif battle.state == battle.States.PLAYER_TARGET:
		menu_is_visible = battle._enemies_menu.visible

	if node is BaseButton and menu_is_visible:
		_set_target(node)
	else:
		hide()
		set_process(false)
		
# Assign new target for cursor and connect exiting signal
func _set_target(node: Control) -> void:
	print("MenuCursor.gd/_set_target() called")
	# Disconnect old target
	if target:
		target.tree_exiting.disconnect(_on_target_tree_exiting)
	# Assign & connect new target
	target = node
	target.tree_exiting.connect(_on_target_tree_exiting)
	# Position & show cursor
	global_position = target.global_position + OFFSET
	show()
	set_process(true)
	if move_sound.stream:
		move_sound.play()
