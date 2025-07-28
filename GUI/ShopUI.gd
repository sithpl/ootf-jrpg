class_name ShopUI extends Control

# Signals
signal item_purchased(item: Item, amount: int) # Emitted when an item is bought
signal item_selected(item: Item) # Emitted when an item is elected

# UI references
@onready var startui : StartUI = $StartUI
@onready var shopui: ShopUI = $"."
@onready var shop_cursor: ShopCursor = $ShopCursor
@onready var item_list: VBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList
@onready var sell_list: VBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/SellList
@onready var buy_header_row: HBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList/HeaderRow
@onready var sell_header_row: HBoxContainer = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList/HeaderRow
@onready var buy_button: Button = $MarginContainer/Window/VBoxContainer/Top/Select/MarginContainer/HBoxContainer/Buy
@onready var sell_button: Button = $MarginContainer/Window/VBoxContainer/Top/Select/MarginContainer/HBoxContainer/Sell
@onready var exit_button: Button = $MarginContainer/Window/VBoxContainer/Top/Select/MarginContainer/HBoxContainer/Exit
@onready var qty_label: Label = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/ItemList/HeaderRow/Qty
@onready var detail_label: Label = $MarginContainer/Window/VBoxContainer/Bottom/ItemDetail/MarginContainer/Detail

const Item = preload("res://Items/Item.gd")

var shop_theme = MusicManager.ThemeType.SHOP
var last_items_with_stock: Array = []
var last_focused_item_id: String = ""
var last_focused_sell_item_id: String = ""
var is_open: bool = false
var shop_mode: String = "menu" # "menu" or "buy"


func _ready():
	buy_button.connect("pressed", Callable(self, "_on_buy_pressed"))
	sell_button.connect("pressed", Callable(self, "_on_sell_pressed"))
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))

	# Prevent focus on menu buttons in buy mode
	buy_button.connect("focus_entered", Callable(self, "_on_menu_button_focus_entered"))
	sell_button.connect("focus_entered", Callable(self, "_on_menu_button_focus_entered"))
	exit_button.connect("focus_entered", Callable(self, "_on_menu_button_focus_entered"))

func _process(delta):
	# This is non-intrusive and always works
	if shop_mode == "buy" and not _has_enabled_buy_buttons():
		_show_menu()

# Open the shop UI
func open():
	if is_open:
		visible = true
		shop_cursor.visible = true
		get_tree().paused = true
		Globals.player.movement_locked = true
		_show_menu()
		buy_button.grab_focus()
		return
	sell_list.visible = false
	shop_cursor.visible = true
	get_tree().paused = true
	visible = true
	Globals.player.movement_locked = true
	MusicManager.play_type_theme(shop_theme)
	is_open = true
	_show_menu()
	buy_button.grab_focus()

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

func _unhandled_input(event):
	#print("_unhandled_input called. event: ", event, " shop_mode: ", shop_mode, " focus owner: ", get_viewport().gui_get_focus_owner())
	if shopui.visible:
		if event.is_action_pressed("ui_cancel"):
			if shop_mode == "buy":
				_show_menu()
			elif shop_mode == "sell":
				_show_menu()
			elif shop_mode == "menu":
				close()

func _show_menu():
	shop_mode = "menu"
	set_menu_focus_enabled(true, false)
	buy_button.grab_focus()
	detail_label.text = ""

func _on_buy_pressed():
	shop_mode = "buy"
	_enable_buy_buttons()
	set_menu_focus_enabled(false, true)
	item_list.visible = true
	sell_list.visible = false

	var has_enabled = false
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		var btn = row.get_child(0)
		if not btn.disabled:
			has_enabled = true
			break

	if not has_enabled:
		_show_menu()
		return

	# Focus the first enabled buy button
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		var btn = row.get_child(0)
		if not btn.disabled:
			btn.grab_focus()
			break

# Helper: Enable buy buttons (when in buy mode)
func _enable_buy_buttons():
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		var btn = row.get_child(0)
		btn.disabled = btn.get_meta("stock") == 0

func _has_enabled_buy_buttons() -> bool:
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		var btn = row.get_child(0)
		if not btn.disabled:
			return true
	return false

# Helper: get item id for a row
func _get_button_row_item_id(row_idx):
	var row = item_list.get_child(row_idx)
	var btn = row.get_child(0)
	return btn.get_meta("item_id")

# Update shop items UI with current stock
func populate_buy_items(items_with_stock: Array):
	last_items_with_stock = items_with_stock.duplicate()
	var num_existing = item_list.get_child_count() - 1
	var num_new = items_with_stock.size()

	for idx in range(max(num_existing, num_new)):
		if idx < num_new:
			var entry = items_with_stock[idx]
			var item = entry["item"]
			var stock = entry.get("stock", null)
			var row: HBoxContainer = null

			if idx < num_existing:
				# Reuse row
				row = item_list.get_child(idx + 1)
				var item_label = row.get_child(0)
				item_label.text = item.name
				item_label.set_meta("item_id", item.id)
				item_label.disabled = stock == 0

				var qty_label = row.get_child(1)
				qty_label.text = str(stock)

				var price_label = row.get_child(2)
				price_label.text = str(item.price)
			else:
				# Add new row
				row = HBoxContainer.new()
				row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				var item_label = Button.new()
				item_label.text = item.name
				item_label.alignment = HORIZONTAL_ALIGNMENT_LEFT
				item_label.custom_minimum_size.x = 100
				item_label.focus_mode = Control.FOCUS_ALL
				item_label.set_meta("item_id", item.id)
				item_label.set_meta("stock", stock) 
				item_label.disabled = stock == 0
				row.add_child(item_label)

				var qty_label = Label.new()
				qty_label.custom_minimum_size.x = 35  
				qty_label.text = str(stock)
				row.add_child(qty_label)

				var price_label = Label.new()
				price_label.custom_minimum_size.x = 35
				price_label.text = str(item.price)
				row.add_child(price_label)

				# (Add description label if needed elsewhere)
				item_label.connect("pressed", Callable(self, "_on_button_pressed").bind(idx))
				item_label.connect("focus_entered", Callable(self, "_on_button_focus_entered").bind(idx))
				item_list.add_child(row)
		elif idx < num_existing:
			item_list.get_child(idx + 1).queue_free()

	restore_list_focus(item_list, last_focused_item_id)

# Handle buy button pressed
func _on_button_pressed(idx: int):
	if idx < 0 or idx >= last_items_with_stock.size():
		return
	var entry = last_items_with_stock[idx]
	var item = entry["item"]
	var stock = entry.get("stock", 0)
	if stock > 0:
		last_focused_item_id = item.id
		emit_signal("item_purchased", item, 1)
		# After the purchase, update the UI (e.g., repopulate_items)
		populate_buy_items(last_items_with_stock)
		#DEBUG print("get_tree().paused: ", get_tree().paused)

# Handle item focus change
func _on_button_focus_entered(idx: int):
	if idx < 0 or idx >= last_items_with_stock.size():
		return
	var entry = last_items_with_stock[idx]
	var item = entry["item"]
	last_focused_item_id = item.id
	emit_signal("item_selected", item)
	detail_label.text = item.description

func _on_menu_button_focus_entered():
	if shop_mode == "buy":
		# Restore focus to last focused item
		var button_to_focus: Button = null
		for idx in range(1, item_list.get_child_count()):
			var row = item_list.get_child(idx)
			var btn = row.get_child(0)
			if btn.get_meta("item_id") == last_focused_item_id and not btn.disabled:
				button_to_focus = btn
				break
		if button_to_focus == null:
			# Fallback to the first enabled buy button
			for idx in range(1, item_list.get_child_count()):
				var row = item_list.get_child(idx)
				var btn = row.get_child(0)
				if not btn.disabled:
					button_to_focus = btn
					break
		if button_to_focus:
			button_to_focus.grab_focus()

func set_menu_focus_enabled(menu_enabled: bool, itemlist_enabled: bool):
	# Menu buttons
	buy_button.focus_mode = Control.FOCUS_ALL if menu_enabled else Control.FOCUS_NONE
	sell_button.focus_mode = Control.FOCUS_ALL if menu_enabled else Control.FOCUS_NONE
	exit_button.focus_mode = Control.FOCUS_ALL if menu_enabled else Control.FOCUS_NONE

	# Item List buttons
	for i in range(1, item_list.get_child_count()):
		var row = item_list.get_child(i)
		var btn = row.get_child(0)
		btn.focus_mode = Control.FOCUS_ALL if itemlist_enabled else Control.FOCUS_NONE

# Populate the sell list with player's inventory
func populate_sell_items(inventory_dict: Dictionary) -> void:
	print("ShopUI.gd/populate_sell_items() called")
	# Ensure sell_list is the correct node path
	var sell_list = sell_list

	# Clear previous entries
	for i in range(1, sell_list.get_child_count()):
		sell_list.get_child(i).queue_free()

	# Populate with items from inventory_dict
	for item_id in inventory_dict.keys():
		var count = inventory_dict[item_id]
		print(item_id)
		if count <= 0:
			continue

		var item = Item.get_item(item_id)
		if item == null:
			continue

		var sell_price = int(item.price * Item.SELL_PERCENT)

		# Add new row
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Item name label
		var item_label = Button.new()
		item_label.text = item.name
		item_label.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_label.custom_minimum_size.x = 100
		item_label.focus_mode = Control.FOCUS_ALL
		item_label.set_meta("item_id", item.id)
		row.add_child(item_label)

		# Quantity label
		var qty_label = Label.new()
		qty_label.custom_minimum_size.x = 35  
		qty_label.text = str(count)
		row.add_child(qty_label)

		# Price label
		var price_label = Label.new()
		price_label.custom_minimum_size.x = 35 
		price_label.text = str(sell_price)
		row.add_child(price_label)

		# Add row to sell_list
		item_label.connect("focus_entered", Callable(self, "_on_sell_button_focus_entered").bind(item_id))
		item_label.connect("pressed", Callable(self, "_on_sell_button_pressed").bind(item_id))
		sell_list.add_child(row)
		
	print("populate_sell_items: sell_list children count: ", sell_list.get_child_count())
	if sell_list.get_child_count() == 1:
		print("Only header left in sell_list. Switching to menu.")
		_show_menu()
	else:
		print("Restoring focus in sell_list. Last focused: ", last_focused_sell_item_id)
		restore_list_focus(sell_list, last_focused_sell_item_id)
	print("Focus owner after populating sell items: ", get_viewport().gui_get_focus_owner())

func _on_sell_pressed():
	print("ShopUI.gd/_on_sell_pressed() called")
	shop_mode = "sell"
	set_menu_focus_enabled(false, true)
	populate_sell_items(PlayerInventory.items)
	item_list.visible = false
	sell_list.visible = true
	buy_header_row.visible = false
	sell_header_row.visible = true
	shop_cursor.visible = true
	print("ShopUI.gd/_on_sell_pressed() -> shop_cursor.visible = true")

func _on_sell_button_pressed(item_id):
	#DEBUG print("ShopUI.gd/_on_sell_button_pressed called for ", item_id)
	var quantity = PlayerInventory.items.get(item_id, 0)
	print("Quantity before selling: ", quantity)
	if quantity > 0:
		var item = Item.get_item(item_id)
		var sell_price = int(item.price * Item.SELL_PERCENT)
		PlayerInventory.money += sell_price
		print(PlayerInventory.money)
		PlayerInventory.items[item_id] -= 1
		if PlayerInventory.items[item_id] <= 0:
			PlayerInventory.items.erase(item_id)
		populate_sell_items(PlayerInventory.items)
		print("Called populate_sell_items after selling")
		print("Focus owner after selling: ", get_viewport().gui_get_focus_owner())
		print("get_tree().paused: ", get_tree().paused)

func _on_sell_button_focus_entered(item_id):
	#DEBUG print("ShopUI.gd/_on_sell_button_focus_entered() called")
	last_focused_sell_item_id = item_id
	var item = Item.get_item(item_id)
	emit_signal("item_selected", item)
	detail_label.text = item.description + " : " + item.type
	
func _on_exit_pressed():
	close()

func restore_list_focus(list: VBoxContainer, last_focused_item_id: String, skip_header := true):
	#DEBUG print("ShopUI.gd/restore_list_focus() called")
	var start_idx = 1 if skip_header else 0
	var button_to_focus: Button = null

	#DEBUG print("restore_list_focus called on ", list.name, " with last_focused_item_id: ", last_focused_item_id)

	for idx in range(start_idx, list.get_child_count()):
		var row = list.get_child(idx)
		if row.get_child_count() == 0:
			continue
		var btn = row.get_child(0)
		#DEBUG print("Checking button in row ", idx, ": ", btn.text, " id=", btn.get_meta("item_id"), " disabled=", btn.disabled)
		if btn.has_meta("item_id") and btn.get_meta("item_id") == last_focused_item_id and not btn.disabled:
			button_to_focus = btn
			#DEBUG print("Found matching button to focus: ", btn.text)
			break

	if button_to_focus == null:
		for idx in range(start_idx, list.get_child_count()):
			var row = list.get_child(idx)
			if row.get_child_count() == 0:
				continue
			var btn = row.get_child(0)
			if not btn.disabled:
				button_to_focus = btn
				#DEBUG print("Focusing first enabled button: ", btn.text)
				break

	if button_to_focus:
		#DEBUG print("Grabbing focus for: ", button_to_focus.text)
		if button_to_focus.focus_mode == Control.FOCUS_NONE:
			#DEBUG print("Button had FOCUS_NONE, switching to FOCUS_ALL")
			button_to_focus.focus_mode = Control.FOCUS_ALL
		button_to_focus.grab_focus()
	else:
		#DEBUG print("No button to focus, focusing exit_button")
		exit_button.grab_focus()

	#DEBUG print("After restore_list_focus: Focus owner is ", get_viewport().gui_get_focus_owner())
