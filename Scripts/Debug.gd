extends Node

const PRINT_CURRENT_FOCUS: bool = false  # Toggle printing of GUI focus changes for debugging

# Called when the node is added to the scene tree
func _ready():
	if PRINT_CURRENT_FOCUS:
		# Connect to GUI focus change signal for debugging
		get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)

# Handles global key input for debugging controls
func _unhandled_key_input(event: InputEvent) -> void:
	var fuck_you_godot_4_a_little_bit: InputEventKey = event
	if event.is_pressed():
		var key: int = fuck_you_godot_4_a_little_bit.keycode
		match key:
			KEY_R:
				get_tree().reload_current_scene()   # Reload the current scene
			KEY_Q:
				get_tree().quit()                   # Quit the game
			KEY_F11:
				var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				var target_mode: int = DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(target_mode)  # Toggle fullscreen/windowed

# Prints the currently focused GUI node (if PRINT_CURRENT_FOCUS is true)
func _on_viewport_gui_focus_changed(node: Control):
	print(node)
