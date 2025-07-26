class_name ShopUI extends Control

signal item_purchased(item: Item, amount: int)
signal item_selected(item: Item)

@onready var shopui: ShopUI = $"."
@onready var shop_cursor: ShopCursor = $ShopCursor
@onready var item_list: VBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList
@onready var header_row: HBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList/HeaderRow

var shop_theme = MusicManager.ThemeType.SHOP
var last_items_with_stock: Array = []

func open():
	shop_cursor.visible = true
	get_tree().paused = true
	visible = true
	Globals.player.movement_locked = true
	grab_focus()
	MusicManager.play_type_theme(shop_theme)

func close():
	get_tree().paused = false
	visible = false
	Globals.player.movement_locked = false
	var game_node = get_tree().current_scene
	if game_node and game_node.get_child_count() > 0:
		var area_node = null
		for child in game_node.get_children():
			if "area_theme" in child:
				area_node = child
				break
		if "area_theme" in area_node:
			MusicManager.play_type_theme(area_node.area_theme)
		else:
			print("Warning: area_theme not found on area node!")
	else:
		print("Warning: No area node found as child of Game!")
	#emit_signal("shop_closed")

func _unhandled_input(event):
	if shopui.visible and event.is_action_pressed("ui_cancel"):
		close()

# items_with_stock: Array of {item: Item, stock: int} as built by Shopkeeper
func populate_items(items_with_stock: Array):
	print("ShopUI.gd/populate_items() called")
	last_items_with_stock = items_with_stock.duplicate()
	# Clear previous item rows (keep header at index 0)
	for i in range(item_list.get_child_count() - 1, 0, -1):
		item_list.get_child(i).queue_free()

	# Ensure header row is not focusable by ShopCursor
	for child in header_row.get_children():
		if child is Button or child is Label:
			child.focus_mode = Control.FOCUS_NONE

	var first_button: Button = null

	for entry in items_with_stock:
		var item = entry["item"]
		var stock = entry.get("stock", null)

		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Item Button
		var btn = Button.new()
		btn.text = item.name + (" x%d" % stock if stock != null else "")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.custom_minimum_size.x = 70
		btn.focus_mode = Control.FOCUS_ALL
		row.add_child(btn)
		if first_button == null:
			first_button = btn

		# Price Label
		var label_price = Label.new()
		label_price.custom_minimum_size.x = 35
		label_price.text = str(item.price)
		row.add_child(label_price)

		# Info Label
		var label_info = Label.new()
		label_info.custom_minimum_size.x = 105
		label_info.text = item.description
		row.add_child(label_info)

		btn.connect("pressed", Callable(self, "_on_button_pressed").bind(entry))
		print("pressed -> ", entry)
		btn.connect("focus_entered", Callable(self, "_on_button_focus_entered").bind(entry))
		print("focus_entered -> ", entry)

		item_list.add_child(row)
		print("Added row for ", item.name)
	
	# Focus the first button so MenuCursor appears
	if first_button:
		first_button.grab_focus()

func _on_button_pressed(idx: int):
	if idx < 0 or idx >= last_items_with_stock.size():
		return
	var entry = last_items_with_stock[idx]
	var item = entry["item"]
	var stock = entry.get("stock", 0)
	if stock > 0:
		emit_signal("item_purchased", item, 1)
		print("item_purchased :", item, " = ", 1)

func _on_button_focus_entered(idx: int):
	if idx < 0 or idx >= last_items_with_stock.size():
		return
	var entry = last_items_with_stock[idx]
	var item = entry["item"]
	emit_signal("item_selected", item)
	print("item_selected: ", item)
