class_name CharacterSlot extends NinePatchRect

@onready var char_portrait : TextureRect = $MarginContainer/HBoxContainer/VBoxContainer/Portrait
@onready var char_name : Label = $MarginContainer/HBoxContainer/VBoxContainer2/Name
@onready var char_class : Label = $MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Class
@onready var char_hp : Label = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/HP#"
@onready var char_ap : Label = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/AP#"
@onready var char_spd : Label = $"MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/SPD#"

func set_character(name: String, portrait_path: String, hp: int, hp_max: int, ap: int, ap_max: int, spd: int):
	char_name.text = name
	char_portrait.texture = load(portrait_path) if portrait_path != "" else null
	char_hp.text = "%d/%d" % [hp, hp_max]
	char_ap.text = "%d/%d" % [ap, ap_max]
	char_spd.text = str(spd)
	# Get the class from Data.gd
	if name != "" and Data.characters.has(name):
		char_class.text = Data.characters[name]["class"]
	else:
		char_class.text = ""
