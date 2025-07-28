class_name InventoryMenu extends Control

@onready var item_menu : HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/ItemMenu/MarginContainer/HBoxContainer
@onready var use_button : Button = $MarginContainer/VBoxContainer/HBoxContainer/ItemMenu/MarginContainer/HBoxContainer/Use
@onready var arrange_button: Button  = $MarginContainer/VBoxContainer/HBoxContainer/ItemMenu/MarginContainer/HBoxContainer/Arrange
@onready var quest_button: Button  = $MarginContainer/VBoxContainer/HBoxContainer/ItemMenu/MarginContainer/HBoxContainer/Quest

@onready var detail_label : Label = $MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect/MarginContainer/Detail
@onready var total_items : Label = $MarginContainer/VBoxContainer/HBoxContainer2/NinePatchRect/MarginContainer/TotalItems

@onready var item_list : VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer3/NinePatchRect/MarginContainer/ItemList
@onready var item_header_row : HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer3/NinePatchRect/MarginContainer/ItemList/ItemHeaderRow
@onready var item_button : Button = $MarginContainer/VBoxContainer/HBoxContainer3/NinePatchRect/MarginContainer/ItemList/ItemHeaderRow/Item
@onready var quantity_label : Label = $MarginContainer/VBoxContainer/HBoxContainer3/NinePatchRect/MarginContainer/ItemList/ItemHeaderRow/Qty
@onready var type_label : Label = $MarginContainer/VBoxContainer/HBoxContainer3/NinePatchRect/MarginContainer/ItemList/ItemHeaderRow/Type

var player_inventory: Node = null

func _ready():
	Item.register_items()
	set_process_unhandled_input(true)
	for child in item_header_row.get_children():
		if child is Control:
			child.focus_mode = Control.FOCUS_NONE
	
	use_button.connect("pressed", Callable(self, "_on_use_pressed"))
	arrange_button.connect("pressed", Callable(self, "_on_arrange_pressed"))
	quest_button.connect("pressed", Callable(self, "_on_quest_pressed"))

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# Check if an item button is focused
		var focus_owner = get_viewport().gui_get_focus_owner()
		var in_item_list = false

		# Check if focus_owner an item buttons in item_list
		for i in range(1, item_list.get_child_count()):
			var row = item_list.get_child(i)
			if row.get_child_count() > 0 and row.get_child(0) == focus_owner:
				in_item_list = true
				break

		if in_item_list:
			# Restore focus modes
			set_item_menu_focus_enabled(true)
			set_item_buttons_focus_enabled(false)
			# Focus USE button
			use_button.grab_focus()
			get_viewport().set_input_as_handled()

func focus_item_menu():
	use_button.grab_focus()
	set_item_menu_focus_enabled(true)
	# Disable focus for item buttons
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		if row.get_child_count() > 0:
			var btn = row.get_child(0)
			if btn is Button:
				btn.focus_mode = Control.FOCUS_NONE
	populate_inventory_items(PlayerInventory.items)

func _on_use_pressed():
	print("InventoryMenu.gd/_on_use_pressed() called")
	set_item_menu_focus_enabled(false)
	set_item_buttons_focus_enabled(true)
	if item_list.get_child_count() > 1:
		var first_row = item_list.get_child(1)
		if first_row.get_child_count() > 0:
			var first_button = first_row.get_child(0)
			if first_button is Button:
				first_button.grab_focus()

func _on_arrange_pressed():
	pass

func _on_quest_pressed():
	pass

func set_item_menu_focus_enabled(menu_enabled: bool):
	use_button.focus_mode = Control.FOCUS_ALL if menu_enabled else Control.FOCUS_NONE
	arrange_button.focus_mode = Control.FOCUS_ALL if menu_enabled else Control.FOCUS_NONE
	quest_button.focus_mode = Control.FOCUS_ALL if menu_enabled else Control.FOCUS_NONE

func set_item_buttons_focus_enabled(enable: bool):
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		if row.get_child_count() > 0:
			var btn = row.get_child(0)
			if btn is Button:
				btn.focus_mode = Control.FOCUS_ALL if enable else Control.FOCUS_NONE

func populate_inventory_items(inventory_dict: Dictionary) -> void:
	print("InventoryMenu.gd/populate_inventory_items() called")
	# Clear previous entries (leave header if present at 0)
	for i in range(1, item_list.get_child_count()):
		item_list.get_child(i).queue_free()

	for item_id in inventory_dict.keys():
		var count = inventory_dict[item_id]
		if count <= 0:
			continue

		var item = Item.get_item(item_id)
		if item == null:
			continue

		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var item_button = Button.new()
		item_button.text = item.name
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.custom_minimum_size.x = 100
		item_button.focus_mode = Control.FOCUS_NONE
		item_button.set_meta("item_id", item.id)
		item_button.disabled = not (item.type == "Consume")
		row.add_child(item_button)

		var qty_label = Label.new()
		qty_label.custom_minimum_size.x = 15
		qty_label.text = str(count)
		row.add_child(qty_label)

		var type_label = Label.new()
		type_label.custom_minimum_size.x = 60
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		type_label.text = item.type if "type" in item else ""
		row.add_child(type_label)

		item_button.connect("focus_entered", Callable(self, "_on_inventory_item_focus_entered").bind(item_id))
		item_button.connect("pressed", Callable(self, "_on_inventory_item_pressed").bind(item_id))

		item_list.add_child(row)
	
	update_total_items()
	print("InventoryMenu: item_list children count: ", item_list.get_child_count())

func _on_inventory_item_focus_entered(item_id):
	show_item_description(item_id)

func show_item_description(item_id):
	var item = Item.get_item(item_id)
	if item:
		detail_label.text = item.description
	else:
		detail_label.text = ""

func _on_item_selected(index):
	var items = PlayerInventory.get_all_items()
	if index >= 0 and index < items.size():
		var item_id = items[index].item_id
		show_item_description(item_id)
		quantity_label.text = str(items[index].count)

func update_total_items():
	var total = 0
	for count in PlayerInventory.items.values():
		total += int(count)
	total_items.text = str(total)
