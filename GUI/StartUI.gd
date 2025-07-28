class_name StartUI extends CanvasLayer

@onready var start_cursor : StartCursor = $StartMenu/StartCursor
@onready var startui : StartUI = $"."
@onready var start_menu : Control = $StartMenu
@onready var inventory_menu : Control = $InventoryMenu
@onready var item_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Item
@onready var magic_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Magic
@onready var equip_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Equip
@onready var check_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Check
@onready var save_button : Button = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Save
@onready var current_money_text : Label = $StartMenu/HBoxContainer/Left/VBoxContainer/Info/MarginContainer/VBoxContainer/HBoxContainer/Resource
@onready var total_time_label : Label = $StartMenu/HBoxContainer/Left/VBoxContainer/Info/MarginContainer/VBoxContainer/Played/TotalTime

const InventoryMenu = preload("res://GUI/InventoryMenu.tscn")

var party_keys = Data.party_keys  # ["Bili", "Glenn", "Fraud", "Rage"]

@onready var slots = [
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot1,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot2,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot3,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot4
]

func _ready():
	#DEBUG print("StartUI.gd/_ready() called")
	set_process_unhandled_input(true)
	if inventory_menu:
		inventory_menu.hide()
	PlayerInventory.connect("money_changed", Callable(self, "get_current_money"))
	item_button.connect("pressed", Callable(self, "_on_item_pressed"))
	magic_button.connect("pressed", Callable(self, "_on_magic_pressed"))
	equip_button.connect("pressed", Callable(self, "_on_equip_pressed"))
	check_button.connect("pressed", Callable(self, "_on_check_pressed"))
	save_button.connect("pressed", Callable(self, "_on_save_pressed"))

func _process(_delta):
	total_time_label.text = GameTimer.get_time_string()

func open_menu():
	#DEBUG print("StartUI.gd/open_menu() called")
	startui.visible = true
	start_cursor.visible = true
	item_button.grab_focus()
	TextUi.hide()
	get_current_money()
	update_character_slots()
	$StartMenu/AnimationPlayer.play("fade_in")  # Play fade_in animation
	await $StartMenu/AnimationPlayer.animation_finished

func close_menu():
	#DEBUG print("StartUI.gd/close_menu() called")
	$StartMenu/AnimationPlayer.play("fade_out")  # Play fade_in animation
	await $StartMenu/AnimationPlayer.animation_finished
	start_cursor.visible = false
	startui.visible = false
	TextUi.show()

func get_current_money():
	#DEBUG print("StartUI.gd/get_current_money() called")
	var current_money : int = PlayerInventory.money
	#DEBUG print("Money label update: ", current_money)
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

func _on_item_pressed():
	print("StartUI.gd/_on_item_pressed() called")
	if inventory_menu:
		$StartMenu/AnimationPlayer.play("fade_out")
		await $StartMenu/AnimationPlayer.animation_finished
		inventory_menu.visible = true
		inventory_menu.focus_item_menu()
	else:
		pass

func _on_magic_pressed():
	print("StartUI.gd/_on_magic_pressed() called")

func _on_equip_pressed():
	print("StartUI.gd/_on_equip_pressed() called")

func _on_check_pressed():
	print("StartUI.gd/_on_check_pressed() called")

func _on_save_pressed():
	print("StartUI.gd/_on_save_pressed() called")
