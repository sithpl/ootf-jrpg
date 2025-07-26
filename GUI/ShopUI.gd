class_name ShopUI extends Control

# Signals
signal item_purchased(item: Item, amount: int) # Emitted when an item is bought
signal item_selected(item: Item) # Emitted when an item is elected

# UI references
@onready var shopui: ShopUI = $"."
@onready var shop_cursor: ShopCursor = $ShopCursor
@onready var item_list: VBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList
@onready var header_row: HBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList/HeaderRow

var shop_theme = MusicManager.ThemeType.SHOP
var last_items_with_stock: Array = []
var last_focused_item_id: String = ""
var is_open: bool = false

# Open the shop UI
func open():
	if is_open:
		visible = true
		shop_cursor.visible = true
		get_tree().paused = true
		Globals.player.movement_locked = true
		return
	shop_cursor.visible = true
	get_tree().paused = true
	visible = true
	Globals.player.movement_locked = true
	MusicManager.play_type_theme(shop_theme)
	is_open = true

# Close the shop UI and restore previous music
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
	is_open = false

# Handle shop cancel input
func _unhandled_input(event):
	if shopui.visible and event.is_action_pressed("ui_cancel"):
		close()

# Helper: get item id for a row
func _get_button_row_item_id(row_idx):
	var row = item_list.get_child(row_idx)
	var btn = row.get_child(0)
	return btn.get_meta("item_id")

# Update shop items UI with current stock
func populate_items(items_with_stock: Array):
	last_items_with_stock = items_with_stock.duplicate()
	var num_existing = item_list.get_child_count() - 1
	var num_new = items_with_stock.size()

	# Update or create rows as needed
	for idx in range(max(num_existing, num_new)):
		if idx < num_new:
			var entry = items_with_stock[idx]
			var item = entry["item"]
			var stock = entry.get("stock", null)
			var row: HBoxContainer = null

			if idx < num_existing:
				# Reuse row
				row = item_list.get_child(idx + 1)
				var btn = row.get_child(0)
				btn.text = item.name + (" x%d" % stock if stock != null else "")
				btn.set_meta("item_id", item.id)
				btn.disabled = stock == 0
				row.get_child(1).text = str(item.price)
				row.get_child(2).text = item.description
			else:
				# Add new row
				row = HBoxContainer.new()
				row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var btn = Button.new()
				btn.text = item.name + (" x%d" % stock if stock != null else "")
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.custom_minimum_size.x = 70
				btn.focus_mode = Control.FOCUS_ALL
				btn.set_meta("item_id", item.id)
				btn.disabled = stock == 0
				row.add_child(btn)
				var label_price = Label.new()
				label_price.custom_minimum_size.x = 35
				label_price.text = str(item.price)
				row.add_child(label_price)
				var label_info = Label.new()
				label_info.custom_minimum_size.x = 105
				label_info.text = item.description
				row.add_child(label_info)
				btn.connect("pressed", Callable(self, "_on_button_pressed").bind(idx))
				btn.connect("focus_entered", Callable(self, "_on_button_focus_entered").bind(idx))
				item_list.add_child(row)
		elif idx < num_existing:
			# Remove extra rows
			item_list.get_child(idx + 1).queue_free()

	# Restore button focus
	var button_to_focus: Button = null
	for idx in range(num_new):
		var row = item_list.get_child(idx + 1)
		var btn = row.get_child(0)
		if btn.get_meta("item_id") == last_focused_item_id and not btn.disabled:
			button_to_focus = btn
			break
	if button_to_focus == null:
		for idx in range(num_new):
			var row = item_list.get_child(idx + 1)
			var btn = row.get_child(0)
			if not btn.disabled:
				button_to_focus = btn
				break
	if button_to_focus:
		button_to_focus.grab_focus()

# Handle buy button pressed
func _on_button_pressed(idx: int):
	if idx < 0 or idx >= last_items_with_stock.size():
		return
	var entry = last_items_with_stock[idx]
	var item = entry["item"]
	var stock = entry.get("stock", 0)
	if stock > 0:
		emit_signal("item_purchased", item, 1)

# Handle item focus change
func _on_button_focus_entered(idx: int):
	if idx < 0 or idx >= last_items_with_stock.size():
		return
	var entry = last_items_with_stock[idx]
	var item = entry["item"]
	last_focused_item_id = item.id
	emit_signal("item_selected", item)
