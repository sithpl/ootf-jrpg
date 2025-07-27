class_name TextUI extends CanvasLayer

signal confirmed

@onready var gui = $GUIMargin
@onready var area_name_box = $GUIMargin/AreaNameBox
@onready var area_name_text = $GUIMargin/AreaNameBox/NinePatchRect/MarginContainer/Label
@onready var dialogue_box = $GUIMargin/DialogueBox
@onready var dialogue_text = $GUIMargin/DialogueBox/NinePatchRect/MarginContainer/Label

var waiting_for_confirm = false
var last_visible
var area_timer: SceneTreeTimer = null  # Reference to current area name timer

func _ready():
	set_process_unhandled_input(true)
	area_name_box.visible = false
	dialogue_box.visible = false
	#DEBUG print("Hiding TextUI from ", get_script().resource_path, "; at ", Time.get_ticks_msec())

func _process(_delta):
	if visible != last_visible:
		#DEBUG print("TextUI.gd: visible = ", visible, "; at ", Time.get_ticks_msec(), "; path: ", get_path())
		last_visible = visible

func show_area_name(area_name: String):
	# Cancel previous timer if it exists and is still running
	if area_timer and area_timer.is_connected("timeout", hide_area_name_box):
		area_timer.timeout.disconnect(hide_area_name_box)
		area_timer = null

	area_name_box.show()
	area_name_text.text = area_name
	area_name_box.visible = true

	# Start a new 2-second timer
	area_timer = get_tree().create_timer(2.0)
	area_timer.timeout.connect(hide_area_name_box)

func hide_area_name_box():
	#DEBUG print("TextUI.gd/hide_area_name_box called")
	area_name_box.visible = false

func show_dialogue_box(text: String):
	#DEBUG print("TextUI.show_dialogue_box called with text: ", text)
	dialogue_box.show()
	dialogue_text.text = text
	if waiting_for_confirm:
		#DEBUG print("Already waiting for confirm; ignoring extra call.")
		return
	waiting_for_confirm = true
	await _wait_for_confirm()
	waiting_for_confirm = false

func hide_dialogue_box():
	#DEBUG print("TextUI.gd/hide_dialogue() called")
	dialogue_box.visible = false
	waiting_for_confirm = false
	#DEBUG print("Hiding TextUI from ", get_script().resource_path, "; at ", Time.get_ticks_msec())
	#DEBUG print("TextUI visibility after change: ", self.visible, self.get_path())

func _wait_for_confirm():
	#DEBUG print("TextUI.gd/_wait_for_confirm() called")
	# Wait until key is released
	while Input.is_action_pressed(&"ui_accept"):
		await get_tree().process_frame
	# Wait for a fresh press
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed(&"ui_accept"):
			emit_signal("confirmed")
			break

func _start_confirm_wait():
	await _wait_for_confirm()
