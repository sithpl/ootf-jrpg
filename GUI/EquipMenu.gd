class_name EquipMenu extends Control

signal cancel_pressed

@onready var main_hand_btn        :Button        = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/MHand
@onready var off_hand_btn         :Button        = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/OHand
@onready var head_btn             :Button        = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/Head
@onready var chest_btn            :Button        = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/Equipped/Chest

@onready var char_portrait        :TextureRect   = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/CharacterPortrait
@onready var char_name            :Label         = $MarginContainer/HBoxContainer/Middle/MarginContainer/HBoxContainer/CharacterName

@onready var cur_char_hp          :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/HP#"
@onready var cur_char_ap          :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/AP#"
@onready var cur_char_atk         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/ATK#"
@onready var cur_char_def         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/DEF#"
@onready var cur_char_mag         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/MAG#"
@onready var cur_char_spd         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/CurrentStats#/SPD#"

@onready var aft_char_hp          :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/PostStats#/HP#"
@onready var aft_char_ap          :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/PostStats#/AP#"
@onready var aft_char_atk         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/PostStats#/ATK#"
@onready var aft_char_def         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/PostStats#/DEF#"
@onready var aft_char_mag         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/PostStats#/MAG#"
@onready var aft_char_spd         :Label         = $"MarginContainer/HBoxContainer/Bottom/MarginContainer/HBoxContainer/EquipStats/VBoxContainer/HBoxContainer/PostStats#/SPD#"

func _ready():
	set_process_unhandled_input(true)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("cancel_pressed")

func set_character(name: String, portrait_path: String, base_hp: int, hp_max: int, base_ap: int, ap_max: int, atk: int, def: int, mag: int, spd: int):
	char_name.text = name
	char_portrait.texture = load(portrait_path) if portrait_path != "" else null
	cur_char_hp.text = "%d/%d" % [base_hp, hp_max]
	cur_char_ap.text = "%d/%d" % [base_ap, ap_max]
	cur_char_atk.text = str(atk)
	cur_char_def.text = str(def)
	cur_char_mag.text = str(mag)
	cur_char_spd.text = str(spd)

func set_equipment_buttons(char_name: String) -> void:
	var eq = PlayerInventory.get_equipment_for(char_name)
	main_hand_btn.text = get_item_name(eq.get("M.Hand", null))
	off_hand_btn.text  = get_item_name(eq.get("O.Hand", null))
	head_btn.text      = get_item_name(eq.get("Head", null))
	chest_btn.text     = get_item_name(eq.get("Chest", null))
	
# Helper to get item name or "--"
func get_item_name(item_id):
	if item_id:
		var item = Item.get_item(item_id)
		return item.name if item else item_id
	return "--"
