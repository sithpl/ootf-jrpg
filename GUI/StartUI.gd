class_name StartUI extends CanvasLayer

@onready var start_cursor : StartCursor = $StartMenu/StartCursor
@onready var startui : StartUI = $"."
@onready var item_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Item
@onready var magic_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Magic
@onready var equip_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Equip
@onready var save_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Save
@onready var current_money_text : Label = $StartMenu/HBoxContainer/Left/VBoxContainer/Info/MarginContainer/VBoxContainer/HBoxContainer/Resource
@onready var total_time_label : Label = $StartMenu/HBoxContainer/Left/VBoxContainer/Info/MarginContainer/VBoxContainer/Played/TotalTime

var party_keys = Data.party_keys  # ["Bili", "Glenn", "Fraud", "Rage"]

@onready var slots = [
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot1,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot2,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot3,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot4
]

func _ready():
	print("StartUI.gd/_ready() called")
	set_process_unhandled_input(true)
	PlayerInventory.connect("money_changed", Callable(self, "get_current_money"))

func _process(_delta):
	total_time_label.text = GameTimer.get_time_string()

func open_menu():
	print("StartUI.gd/open_menu() called")
	startui.visible = true
	start_cursor.visible = true
	TextUi.hide()
	get_current_money()
	update_character_slots()
	item_button.grab_focus()

func close_menu():
	print("StartUI.gd/close_menu() called")
	start_cursor.visible = false
	startui.visible = false
	TextUi.show()

func get_current_money():
	print("StartUI.gd/get_current_money() called")
	var current_money : int = PlayerInventory.money
	print("Money label update: ", current_money)
	current_money_text.text = str(current_money)

func update_character_slots():
	var party_keys = Data.party_keys
	var party = Data.party

	for i in range(slots.size()):
		var slot = slots[i]
		if slot == null:
			print("CharacterSlot instance at index %d is null!" % i)
			continue
		if i < party_keys.size():
			var char_name = party_keys[i]
			var char_data = Data.characters[char_name]
			var actor = party[i]
			var portrait_path = char_data.get("portrait", "")
			slot.set_character(char_name, portrait_path, actor.base_hp, actor.hp_max, actor.base_ap, actor.ap_max, actor.attack, actor.defense, actor.magic, actor.speed)
		else:
			slot.set_character("", "", 0, 0, 0, 0, 0)
