class_name ItemMenu extends Control

# ---------- TOP ----------
@onready var item_menu        :HBoxContainer  = $MarginContainer/VBoxContainer/Top/ItemMenu/MarginContainer/HBoxContainer
@onready var use_button       :Button         = $MarginContainer/VBoxContainer/Top/ItemMenu/MarginContainer/HBoxContainer/Use
@onready var arrange_button   :Button         = $MarginContainer/VBoxContainer/Top/ItemMenu/MarginContainer/HBoxContainer/Arrange
@onready var quest_button     :Button         = $MarginContainer/VBoxContainer/Top/ItemMenu/MarginContainer/HBoxContainer/Quest

# ---------- MIDDLE ----------
@onready var detail_label     :Label          = $MarginContainer/VBoxContainer/Middle/ItemDetail/MarginContainer/Detail
@onready var total_items      :Label          = $MarginContainer/VBoxContainer/Middle/ItemDetail/MarginContainer/TotalItems

# ---------- BOTTOM ----------
@onready var item_list        :VBoxContainer  = $MarginContainer/VBoxContainer/Bottom/ItemList/MarginContainer/ItemList
@onready var item_header_row  :HBoxContainer  = $MarginContainer/VBoxContainer/Bottom/ItemList/MarginContainer/ItemList/ItemHeaderRow
@onready var item_button      :Button         = $MarginContainer/VBoxContainer/Bottom/ItemList/MarginContainer/ItemList/ItemHeaderRow/Item
@onready var quantity_label   :Label          = $MarginContainer/VBoxContainer/Bottom/ItemList/MarginContainer/ItemList/ItemHeaderRow/Qty
@onready var type_label       :Label          = $MarginContainer/VBoxContainer/Bottom/ItemList/MarginContainer/ItemList/ItemHeaderRow/Type
@onready var use_menu         :Control        = $UseMenu

var player_inventory: Node = null
var selected_item_id = null
var use_menu_active = false
var last_focused_item_index: int = 1 
var should_restore_focus := false

func _ready():
	Item.register_items()
	set_process(true)
	set_process_unhandled_input(true)
	use_menu.visible = false
	for child in item_header_row.get_children():
		if child is Control:
			child.focus_mode = Control.FOCUS_NONE
	
	use_button.connect("pressed", Callable(self, "_on_use_pressed"))
	arrange_button.connect("pressed", Callable(self, "_on_arrange_pressed"))
	quest_button.connect("pressed", Callable(self, "_on_quest_pressed"))

func _process(delta):
	if should_restore_focus:
		# Check if UseMenu is REALLY gone
		var found_menu = false
		for child in get_children():
			if child is UseMenu:
				found_menu = true
				break
		if not found_menu:
			should_restore_focus = false
			restore_last_focused_item()

func _unhandled_input(event):
	if use_menu_active:
		return 
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
	print("ItemMenu.gd/_on_use_pressed() called")
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
	print("ItemMenu.gd/populate_inventory_items() called")
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
	print("ItemMenu: item_list children count: ", item_list.get_child_count())

func _on_inventory_item_focus_entered(item_id):
	# Find which row this item is in, and store the index
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		if row.get_child_count() > 0:
			var btn = row.get_child(0)
			if btn is Button and btn.get_meta("item_id") == item_id:
				last_focused_item_index = i
				break
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

func _on_inventory_item_pressed(item_id):
	var item = Item.get_item(item_id)
	if item == null:
		return
	if item.type == "Consume":
		var use_menu_scene = preload("res://GUI/UseMenu.tscn")
		var use_menu = use_menu_scene.instantiate()
		use_menu.set_item(item)
		use_menu.connect("item_used", Callable(self, "_on_use_menu_item_used"))
		use_menu.connect("cancelled", Callable(self, "_on_use_menu_cancelled"), CONNECT_ONE_SHOT)
		add_child(use_menu)
		use_menu.grab_focus()
		use_menu_active = true

func _on_use_menu_item_used():
	populate_inventory_items(PlayerInventory.items)
	update_total_items()

func _on_use_menu_closed():
	use_menu_active = false
	focus_item_menu()
	item_button.grab_focus()

func update_total_items():
	var total = 0
	for count in PlayerInventory.items.values():
		total += int(count)
	total_items.text = str(total)

func _on_use_menu_cancelled():
	print("_on_use_menu_cancelled called!")
	for child in get_children():
		if child is UseMenu:
			child.queue_free()
	use_menu_active = false
	item_list.show()
	should_restore_focus = true

func restore_last_focused_item():
	var row_count = item_list.get_child_count()
	var target_btn : Button = null
	# Clamp index to valid range
	var idx = clamp(last_focused_item_index, 1, row_count-1)
	for i in range(idx, row_count):
		var row = item_list.get_child(i)
		if row.get_child_count() > 0:
			var btn = row.get_child(0)
			if btn is Button and not btn.disabled:
				target_btn = btn
				break
	# If nothing found, search from the top
	if target_btn == null:
		for i in range(1, row_count):
			var row = item_list.get_child(i)
			if row.get_child_count() > 0:
				var btn = row.get_child(0)
				if btn is Button and not btn.disabled:
					target_btn = btn
					break
	if target_btn:
		target_btn.grab_focus()
		print("Restored focus to:", target_btn)
		# Update last_focused_item_index to the new location
		for i in range(1, row_count):
			var row = item_list.get_child(i)
			if row.get_child_count() > 0 and row.get_child(0) == target_btn:
				last_focused_item_index = i
				break
	else:
		print("No valid button to focus!")
