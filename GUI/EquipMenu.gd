class_name EquipMenu extends Control

signal cancel_pressed
signal equipment_changed

@onready var main_hand_btn  :Button      = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/MHand
@onready var off_hand_btn   :Button      = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/OHand
@onready var head_btn       :Button      = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/Head
@onready var chest_btn      :Button      = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/Chest

@onready var equip_items_panel :VBoxContainer = $MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipItems
@onready var equip_item_button :Button        = $MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipItems/Item

@onready var char_portrait   :TextureRect = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/CharacterPortrait
@onready var char_name       :Label       = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/CharacterName

@onready var cur_char_hp     :Label = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/HP#"
@onready var cur_char_ap     :Label = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/AP#"
@onready var cur_char_atk    :Label = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/ATK#"
@onready var cur_char_def    :Label = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/DEF#"
@onready var cur_char_mag    :Label = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/MAG#"
@onready var cur_char_spd    :Label = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/SPD#"

var current_character_name   :String = ""
var current_slot_type        :String = ""     # "M.Hand", "O.Hand", "Head", "Chest"
var slot_button_map          := {}
var item_list_active         := false          # True if player is choosing from the Item list

# Store base stats for the "current" character (for stat preview)
var base_hp  := 0
var hp_max   := 0
var base_ap  := 0
var ap_max   := 0
var base_atk := 0
var base_def := 0
var base_mag := 0
var base_spd := 0

# Store original equipment at EquipMenu open "current" preview
var original_equipment := {}

func _ready():
	set_process_unhandled_input(true)
	slot_button_map = {
		"M.Hand": main_hand_btn,
		"O.Hand": off_hand_btn,
		"Head": head_btn,
		"Chest": chest_btn,
	}
	main_hand_btn.focus_entered.connect(_on_main_hand_focus_entered)
	off_hand_btn.focus_entered.connect(_on_off_hand_focus_entered)
	head_btn.focus_entered.connect(_on_head_focus_entered)
	chest_btn.focus_entered.connect(_on_chest_focus_entered)
	main_hand_btn.pressed.connect(_on_main_hand_btn_pressed)
	off_hand_btn.pressed.connect(_on_off_hand_btn_pressed)
	head_btn.pressed.connect(_on_head_btn_pressed)
	chest_btn.pressed.connect(_on_chest_btn_pressed)
	equip_item_button.visible = false
	equip_items_panel.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if item_list_active:
			item_list_active = false
			_grab_slot_btn_focus()
			_hide_equip_items_panel()
		else:
			emit_signal("equipment_changed")
			emit_signal("cancel_pressed")

func set_character(name: String, portrait_path: String, _base_hp: int, _hp_max: int, _base_ap: int, _ap_max: int, _atk: int, _def: int, _mag: int, _spd: int):
	current_character_name = name
	char_name.text = name
	char_portrait.texture = load(portrait_path) if portrait_path != "" else null

	# Store base stats for preview use
	base_hp = _base_hp
	hp_max = _hp_max
	base_ap = _base_ap
	ap_max = _ap_max
	base_atk = _atk
	base_def = _def
	base_mag = _mag
	base_spd = _spd

	# Store the original equipment (for CURRENT stat preview)
	original_equipment = PlayerInventory.get_equipment_for(name).duplicate()

	set_equipment_buttons(name)
	_update_post_stats() # Show post-equip stats immediately
	main_hand_btn.grab_focus()

func set_equipment_buttons(char_name: String) -> void:
	var eq = PlayerInventory.get_equipment_for(char_name)
	main_hand_btn.text = _get_item_name(eq.get("M.Hand", null))
	off_hand_btn.text  = _get_item_name(eq.get("O.Hand", null))
	head_btn.text      = _get_item_name(eq.get("Head", null))
	chest_btn.text     = _get_item_name(eq.get("Chest", null))

func _get_item_name(item_id):
	if item_id:
		var item = Item.get_item(item_id)
		return item.name if item else item_id
	return "--"

# FOCUS: show the filtered item list, not active/selectable yet
func _on_main_hand_focus_entered():
	_show_equip_items_panel("M.Hand", true)
func _on_off_hand_focus_entered():
	_show_equip_items_panel("O.Hand", true)
func _on_head_focus_entered():
	_show_equip_items_panel("Head", true)
func _on_chest_focus_entered():
	_show_equip_items_panel("Chest", true)

# PRESS: make the list "active" (player can now select), focus first item if exists
func _on_main_hand_btn_pressed():
	_activate_item_list("M.Hand")
func _on_off_hand_btn_pressed():
	_activate_item_list("O.Hand")
func _on_head_btn_pressed():
	_activate_item_list("Head")
func _on_chest_btn_pressed():
	_activate_item_list("Chest")

func _show_equip_items_panel(slot_type: String, highlight_equipped: bool = false):
	current_slot_type = slot_type
	equip_items_panel.visible = true
	_update_equip_items_list(slot_type, highlight_equipped)
	item_list_active = false

func _hide_equip_items_panel():
	equip_items_panel.visible = false

func _activate_item_list(slot_type: String):
	item_list_active = true
	for btn in equip_items_panel.get_children():
		if btn.visible and not btn.disabled:
			btn.grab_focus()
			break

func _grab_slot_btn_focus():
	if current_slot_type in slot_button_map:
		slot_button_map[current_slot_type].grab_focus()

func _update_equip_items_list(slot_type: String, highlight_equipped: bool):
	# Remove old buttons except the template
	for child in equip_items_panel.get_children():
		if child != equip_item_button:
			child.queue_free()
	var eq = PlayerInventory.get_equipment_for(current_character_name)
	var equipped_id = eq.get(slot_type, null)
	var items = _get_items_for_slot_type(slot_type)
	for entry in items:
		var btn = equip_item_button.duplicate()
		btn.visible = true
		# Show item name with count (e.g. "Old Sword (x2)")
		btn.text = "%s (x%d)" % [entry["name"], entry["count"]]
		btn.disabled = entry["count"] <= 0
		if highlight_equipped and entry["item_id"] == equipped_id:
			btn.modulate = Color(0.7, 1, 0.7) # highlight equipped
		else:
			btn.modulate = Color(1, 1, 1)
		btn.pressed.connect(_on_equip_item_selected.bind(entry["item_id"]))
		btn.mouse_entered.connect(_on_equip_item_preview.bind(entry["item_id"]))
		equip_items_panel.add_child(btn)
	# Add unequip option
	var unequip_btn = equip_item_button.duplicate()
	unequip_btn.visible = true
	unequip_btn.text = "-- Unequip --"
	unequip_btn.disabled = false
	#if highlight_equipped and (equipped_id == null or equipped_id == ""):
		#unequip_btn.modulate = Color(0.7, 1, 0.7)
	#else:
		#unequip_btn.modulate = Color(1, 1, 1)
	unequip_btn.pressed.connect(_on_equip_item_selected.bind(""))
	unequip_btn.mouse_entered.connect(_on_equip_item_preview.bind(""))
	equip_items_panel.add_child(unequip_btn)
	_on_equip_item_preview(equipped_id if equipped_id != null else "")

func _get_items_for_slot_type(slot_type: String) -> Array:
	var result = []
	for item_id in PlayerInventory.items.keys():
		var item = Item.get_item(item_id)
		if item and item.type == slot_type:
			var count = PlayerInventory.get_item_count(item_id)
			result.append({"item_id": item_id, "name": item.name, "count": count})
	return result

func _on_equip_item_selected(item_id):
	PlayerInventory.equip_item(current_character_name, current_slot_type, item_id)
	original_equipment = PlayerInventory.get_equipment_for(current_character_name).duplicate()
	set_equipment_buttons(current_character_name)
	_update_post_stats()
	Data.rebuild_party()
	item_list_active = false
	_hide_equip_items_panel()
	_grab_slot_btn_focus()

func _on_equip_item_preview(item_id):
	_update_post_stats(item_id)

func _update_post_stats(preview_item_id = null):
	var eq_current = original_equipment.duplicate()
	var eq_after = eq_current.duplicate()
	if preview_item_id == null or preview_item_id == "":
		eq_after[current_slot_type] = null
	else:
		eq_after[current_slot_type] = preview_item_id

	var base_stats = {
		"attack": base_atk,
		"defense": base_def,
		"magic": base_mag,
		"speed": base_spd,
		"hp_max": hp_max,
		"ap_max": ap_max,
	}

	var current_stats = base_stats.duplicate()
	PlayerInventory.apply_equipment_bonuses(current_stats, eq_current)

	var after_stats = base_stats.duplicate()
	PlayerInventory.apply_equipment_bonuses(after_stats, eq_after)

	cur_char_hp.text  = "%d/%d" % [base_hp, current_stats.hp_max]
	cur_char_ap.text  = "%d/%d" % [base_ap, current_stats.ap_max]
	cur_char_atk.text = str(current_stats.attack)
	cur_char_def.text = str(current_stats.defense)
	cur_char_mag.text = str(current_stats.magic)
	cur_char_spd.text = str(current_stats.speed)
