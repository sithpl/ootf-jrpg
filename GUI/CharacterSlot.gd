class_name CharacterSlot extends NinePatchRect

signal character_selected(index)

@onready var char_portrait    :TextureRect   = $MarginContainer/HBoxContainer/VBoxContainer/Portrait
@onready var char_name        :Label         = $MarginContainer/HBoxContainer/VBoxContainer2/Name
@onready var char_class       :Label         = $MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Class
@onready var char_lvl         :Label         = $MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Level
@onready var char_hp          :Label         = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/HP#"
@onready var char_ap          :Label         = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/AP#"
@onready var char_atk         :Label         = $"MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/ATK#"
@onready var char_def         :Label         = $"MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/DEF#"
@onready var char_mag         :Label         = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/MAG#"
@onready var char_spd         :Label         = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/SPD#"
@onready var select_button    :Button        = $Button

var slot_index := 0

func _ready():
	select_button.connect("pressed", Callable(self, "_on_pressed"))
	select_button.grab_focus()
	select_button.focus_mode = Control.FOCUS_ALL  # Make sure it's focusable

func _on_pressed():
	print("CharacterSlot.gd/_on_pressed() called")
	emit_signal("character_selected", slot_index)

func set_character(name: String, portrait_path: String, base_hp: int, hp_max: int, base_ap: int, ap_max: int, atk: int, def: int, mag: int, spd: int):
	char_name.text = name
	char_portrait.texture = load(portrait_path) if portrait_path != "" else null
	char_hp.text = "%d/%d" % [base_hp, hp_max]
	char_ap.text = "%d/%d" % [base_ap, ap_max]
	char_atk.text = str(atk)
	char_def.text = str(def)
	char_mag.text = str(mag)
	char_spd.text = str(spd)
	
	# Get the class from Data.gd
	if name != "" and Data.characters.has(name):
		char_class.text = Data.characters[name]["class"]
	else:
		char_class.text = ""
