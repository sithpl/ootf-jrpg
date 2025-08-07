class_name StartUI extends CanvasLayer

@onready var anim_player    :AnimationPlayer = $StartMenu/AnimationPlayer
@onready var start_cursor   :StartCursor     = $StartMenu/StartCursor
@onready var startui        :StartUI         = $"."
@onready var start_menu     :Control         = $StartMenu

@onready var item_button    :Button          = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Item
@onready var item_menu      :Control         = $ItemMenu
@onready var skill_button   :Button          = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Skill
@onready var skill_menu     :Control         = $SkillMenu
@onready var equip_button   :Button          = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Equip
@onready var char_list      :VBoxContainer   = $StartMenu/HBoxContainer/Right/Characters
@onready var char_slot1     :Button          = $StartMenu/HBoxContainer/Right/Characters/CharacterSlot1/Button
@onready var char_slot2     :Button          = $StartMenu/HBoxContainer/Right/Characters/CharacterSlot2/Button
@onready var char_slot3     :Button          = $StartMenu/HBoxContainer/Right/Characters/CharacterSlot3/Button
@onready var char_slot4     :Button          = $StartMenu/HBoxContainer/Right/Characters/CharacterSlot4/Button
@onready var equip_menu     :Control         = $EquipMenu
@onready var check_button   :Button          = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Check
@onready var check_menu     :Control         = $CheckMenu
@onready var save_button    :Button          = $StartMenu/HBoxContainer/Left/VBoxContainer/Menu/MarginContainer/VBoxContainer/Save

@onready var current_money_text   :Label   = $StartMenu/HBoxContainer/Left/VBoxContainer/Info/MarginContainer/VBoxContainer/HBoxContainer/Resource
@onready var total_time_label     :Label   = $StartMenu/HBoxContainer/Left/VBoxContainer/Info/MarginContainer/VBoxContainer/Played/TotalTime

const ItemMenu = preload("res://GUI/ItemMenu.tscn")
const EquipMenu = preload("res://GUI/EquipMenu.tscn")

var party_keys = Data.party_keys  # ["Bili", "Glenn", "Fraud", "Rage"]

var menu_state = "main"  # "main", "character_select", "equip_menu", etc.

@onready var slots = [
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot1,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot2,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot3,
	$StartMenu/HBoxContainer/Right/Characters/CharacterSlot4
]

@onready var slot_buttons = [
	char_slot1,
	char_slot2,
	char_slot3,
	char_slot4
]

func _ready():
	#DEBUG print("StartUI.gd/_ready() called")
	equip_menu.visible = false
	set_process_unhandled_input(true)
	if item_menu:
		item_menu.hide()
	PlayerInventory.connect("money_changed", Callable(self, "get_current_money"))
	item_button.connect("pressed", Callable(self, "_on_item_pressed"))
	skill_button.connect("pressed", Callable(self, "_on_skill_pressed"))
	equip_button.connect("pressed", Callable(self, "_on_equip_pressed"))
	check_button.connect("pressed", Callable(self, "_on_check_pressed"))
	save_button.connect("pressed", Callable(self, "_on_save_pressed"))
	for i in range(slots.size()):
		slots[i].slot_index = i  # Assign slot index
		slots[i].connect("character_selected", Callable(self, "_on_character_slot_selected"))
	if equip_menu:
		equip_menu.connect("equipment_changed", Callable(self, "_on_equipment_changed"))
		equip_menu.connect("cancel_pressed", Callable(self, "_on_equipmenu_cancel"))
	#DEBUG print("StartUI.gd/_ready -> Menu: ", menu_state)

func _process(_delta):
	total_time_label.text = GameTimer.get_time_string()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# NEW
		if menu_state == "main":
			# When in the StartMenu, close entire StartUI
			close_menu()
		# EXISTING
		elif menu_state == "character_select":
			# When selecting a character (from Equip), cancel should return to StartMenu without closing StartUI
			menu_state = "main"
			start_menu.visible = true
			start_menu.modulate = Color(1,1,1,1)
			equip_menu.visible = false
			equip_button.grab_focus()
			#DEBUG print("StartUI.gd/_unhandled_input -> Menu: ", menu_state)

func open_menu():
	#DEBUG print("StartUI.gd/open_menu() called")
	menu_state = "main"
	item_menu.visible = false
	equip_menu.visible = false
	skill_menu.visible = false
	check_menu.visible = false
	startui.visible = true
	start_menu.modulate = Color(1,1,1,1)
	start_cursor.visible = true
	item_button.grab_focus()
	TextUi.hide()
	get_current_money()
	update_character_slots()
	$StartMenu/AnimationPlayer.play("fade_in")  # Play fade_in animation
	await $StartMenu/AnimationPlayer.animation_finished
	#DEBUG print("StartUI.gd/open_menu -> Menu: ", menu_state)

func close_menu():
	#DEBUG print("StartUI.gd/close_menu() called")
	menu_state = null
	$StartMenu/AnimationPlayer.play("fade_out")
	await $StartMenu/AnimationPlayer.animation_finished
	start_cursor.visible = false
	startui.visible = false
	TextUi.show()
	Globals.player.movement_locked = false # <----- NEW
	#DEBUG print("StartUI.gd/close_menu -> Menu: ", menu_state)

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
			var portrait_path = Data.characters[char_name].get("portrait", "")
			var actor = party[i]  # <-- Always use the live actor!
			slot.set_character(
				char_name,
				portrait_path,
				actor.base_hp,
				actor.hp_max,
				actor.base_ap,  # <-- Live AP
				actor.ap_max,   # <-- Live AP max
				actor.attack,
				actor.defense,
				actor.magic,
				actor.speed
			)
		else:
			slot.set_character("", "", 0, 0, 0, 0, 0)

func _on_item_pressed():
	#DEBUG print("StartUI.gd/_on_item_pressed() called")
	menu_state = "item_menu"
	if item_menu:
		$StartMenu/AnimationPlayer.play("fade_out")
		await $StartMenu/AnimationPlayer.animation_finished
		item_menu.visible = true
		item_menu.focus_item_menu()
	else:
		pass
	#DEBUG print("StartUI.gd/_on_item_pressed -> Menu: ", menu_state)

func _on_skill_pressed():
	print("StartUI.gd/_on_skill_pressed() called")
	#menu_state = "magic_menu"

func _on_equip_pressed():
	#DEBUG print("StartUI.gd/_on_equip_pressed() called")
	menu_state = "character_select"

	# Set up focus neighbors for buttons in character slot
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		# Set the neighbor above
		if i == 0:
			btn.focus_neighbor_top = btn.get_path()  # char_slot1: top is itself
		else:
			btn.focus_neighbor_top = slot_buttons[i-1].get_path()
		# Set the neighbor below
		if i == slot_buttons.size() - 1:
			btn.focus_neighbor_bottom = btn.get_path()  # char_slot4: bottom is itself
		else:
			btn.focus_neighbor_bottom = slot_buttons[i+1].get_path()
		# Lock left/right neighbors
		btn.focus_neighbor_left = btn.get_path()
		btn.focus_neighbor_right = btn.get_path()

	char_slot1.grab_focus()  # Focus the first button
	#DEBUG print("StartUI.gd/_on_equip_pressed -> Menu: ", menu_state)

func _on_character_slot_selected(index):
	#DEBUG print("StartUI.gd/_on_character_slot_selected() called")
	menu_state = "equip_menu"
	anim_player.play("fade_out")
	await anim_player.animation_finished
	
	# Get character key and data
	var char_name = party_keys[index]
	var char_data = Data.characters[char_name]
	var actor = Data.party[index]
	var portrait_path = char_data.get("portrait", "")

	# Hide StartMenu, show EquipMenu
	start_menu.visible = false
	equip_menu.visible = true

	# Set up the EquipMenu with the selected character's data
	equip_menu.set_character(
		char_name,
		portrait_path,
		actor.base_hp,
		actor.hp_max,
		actor.base_ap,
		actor.ap_max,
		actor.attack,
		actor.defense,
		actor.magic,
		actor.speed
	)
	# Focus the first button in the EquipMenu
	equip_menu.set_equipment_buttons(char_name)
	equip_menu.main_hand_btn.grab_focus()
	#DEBUG print("StartUI.gd/_on_character_slot_selected -> Menu: ", menu_state)

func _on_equipmenu_cancel():
	#DEBUG print("StartUI.gd/_on_equipmenu_cancel() called")
	if menu_state == "equip_menu":
		equip_menu.visible = false
		start_menu.visible = true
		equip_button.grab_focus()
		start_menu.modulate = Color(1,1,1,0) # start fully transparent
		anim_player.play("fade_in")
		await anim_player.animation_finished
		start_menu.modulate = Color(1,1,1,1)
		menu_state = "main" # <----- NEW - Fixes issue with pressing ui_cancel in EquipMenu and backing out of StartUI completely
	#DEBUG print("StartUI.gd/_on_equipment_cancel -> Menu: ", menu_state)

func _on_check_pressed():
	print("StartUI.gd/_on_check_pressed() called")
	#menu_state = "check_menu"

func _on_save_pressed():
	print("StartUI.gd/_on_save_pressed() called")
	#menu_state = "save_menu"

func _on_equipment_changed():
	update_character_slots()
