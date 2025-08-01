class_name UseMenu extends Control

signal item_used
signal cancelled

@onready var start_cursor = $"../StartCursor"
@onready var character_list : VBoxContainer = $NinePatchRect/MarginContainer/CharacterList
@onready var character_name : Button = $NinePatchRect/MarginContainer/CharacterList/CharacterSlot1/CharacterName

var item : Item = null
var prev_button = null
var last_focused_index := 0

func _ready():
	set_process_unhandled_input(true)
	self.focus_mode = Control.FOCUS_ALL
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.grab_focus()
	if item != null:
		populate_party_members()

func _unhandled_input(event):
	#DEBUG print("UseMenu _unhandled_input got event:", event)
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		print("Focus owner is now:", get_viewport().gui_get_focus_owner())
	if event.is_action_pressed("ui_cancel") and self.visible:
		print("ui_cancel pressed in UseMenu!")
		emit_signal("cancelled")
		get_viewport().set_input_as_handled()

func set_item(_item):
	item = _item
	if is_inside_tree():
		populate_party_members()

func populate_party_members():
	if not character_list:
		push_error("character_list is null!")
		return
	# Clear old rows
	for child in character_list.get_children():
		child.queue_free()

	var button_list = []

	for member in Data.party:
		var row = VBoxContainer.new()
		var char_name = Button.new()
		char_name.alignment = HORIZONTAL_ALIGNMENT_LEFT
		char_name.text = member.name
		char_name.focus_mode = Control.FOCUS_ALL
		var is_full_hp = member.base_hp >= member.hp_max
		char_name.set_meta("full_hp", is_full_hp)
		if is_full_hp:
			char_name.modulate = Color(1, 1, 1, 0.5)
		char_name.connect("focus_entered", Callable(self, "_on_button_focus_entered").bind(char_name))
		char_name.connect("pressed", Callable(self, "_on_member_selected").bind(member, char_name))
		row.add_child(char_name)
		var char_hp = Label.new()
		char_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		char_hp.text = "%d/%d" % [member.base_hp, member.hp_max]
		row.add_child(char_hp)
		character_list.add_child(row)
		button_list.append(char_name)

	# Set focus neighbors
	for i in range(button_list.size()):
		var btn = button_list[i]
		btn.focus_neighbor_top = btn.get_path() if i == 0 else button_list[i - 1].get_path()
		btn.focus_neighbor_bottom = btn.get_path() if i == button_list.size() - 1 else button_list[i + 1].get_path()
		btn.focus_neighbor_left = btn.get_path()
		btn.focus_neighbor_right = btn.get_path()

	await get_tree().process_frame
	# Clamp to valid index in new button list
	var focus_index = clamp(last_focused_index, 0, max(0, button_list.size() - 1))
	if button_list.size() > 0:
		button_list[focus_index].grab_focus()

func _on_member_selected(member, button):
	# Store index BEFORE using the item
	for i in range(Data.party.size()):
		if Data.party[i] == member:
			last_focused_index = i
			break
	# If this is a "disabled" button (full HP), do nothing
	if button.get_meta("full_hp", false):
		return
	if item and member:
		item.use(member)
		PlayerInventory.remove_item(item.id, 1)
		emit_signal("item_used")
		populate_party_members()

func _on_button_focus_entered(button):
	print("Focus entered:", button.text)
	start_cursor.global_position = button.global_position
