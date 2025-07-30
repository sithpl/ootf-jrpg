class_name ShopUI extends Control

# Signals
signal item_purchased(item: Item, amount: int) # Emitted when an item is bought
signal item_selected(item: Item) # Emitted when an item is selected

# UI references
@onready var shopui              : ShopUI           = $"."
@onready var startui             : StartUI          = $StartUI
@onready var shop_cursor         : ShopCursor       = $ShopCursor
@onready var buy_button          : Button           = $MarginContainer/Window/VBoxContainer/Top/Select/MarginContainer/HBoxContainer/Buy
@onready var buy_header_row      : HBoxContainer    = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/Buy/BuyHeader
@onready var buy_list            : VBoxContainer    = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/Buy/BuyScroll/BuyList
@onready var sell_header_row     : HBoxContainer    = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/Sell/SellHeader
@onready var sell_list           : VBoxContainer    = $MarginContainer/Window/VBoxContainer/Middle/MarginContainer/Sell/SellScroll/SellList
@onready var sell_button         : Button           = $MarginContainer/Window/VBoxContainer/Top/Select/MarginContainer/HBoxContainer/Sell
@onready var exit_button         : Button           = $MarginContainer/Window/VBoxContainer/Top/Select/MarginContainer/HBoxContainer/Exit
@onready var detail_label        : Label            = $MarginContainer/Window/VBoxContainer/Bottom/ItemDetail/MarginContainer/Detail

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
	if shop_mode == "sell" and get_viewport().gui_get_focus_owner() == null:
		#DEBUG print("Re-grabbing focus on sell!")
		for i in range(1, sell_list.get_child_count()):
			var row = sell_list.get_child(i)
			if row.get_child_count() == 0:
				continue
			var btn = row.get_child(0)
			if not btn.disabled:
				btn.grab_focus()
				break
	if get_viewport().gui_get_focus_owner() == null:
		pass
		#DEBUG print("FOCUS LOST! Call stack:")
		#DEBUG print_stack()

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
	buy_header_row.visible = true
	buy_list.visible = true
	sell_header_row.visible = false
	sell_list.visible = false

	var has_enabled = false
	for i in range(1, buy_list.get_child_count()):
		var row = buy_list.get_child(i)
		var btn = row.get_child(0)
		if not btn.disabled:
			has_enabled = true
			break

	if not has_enabled:
		_show_menu()
		return

	# Focus the first enabled buy button
	for i in range(1, buy_list.get_child_count()):
		var row = buy_list.get_child(i)
		var btn = row.get_child(0)
		if not btn.disabled:
			btn.grab_focus()
			break

# Helper: Enable buy buttons (when in buy mode)
func _enable_buy_buttons():
	for i in range(1, buy_list.get_child_count()):
		var row = buy_list.get_child(i)
		var btn = row.get_child(0)
		btn.disabled = btn.get_meta("stock") == 0

func _has_enabled_buy_buttons() -> bool:
	for i in range(1, buy_list.get_child_count()):
		var row = buy_list.get_child(i)
		var btn = row.get_child(0)
		if not btn.disabled:
			return true
	return false

# Helper: get item id for a row
func _get_button_row_item_id(row_idx):
	var row = buy_list.get_child(row_idx)
	var btn = row.get_child(0)
	return btn.get_meta("item_id")

# Update shop items UI with current stock
func populate_buy_items(items_with_stock: Array):
	last_items_with_stock = items_with_stock.duplicate()
	var num_existing = buy_list.get_child_count() - 1
	var num_new = items_with_stock.size()

	for idx in range(max(num_existing, num_new)):
		if idx < num_new:
			var entry = items_with_stock[idx]
			var item = entry["item"]
			var stock = entry.get("stock", null)
			var row: HBoxContainer = null

			if idx < num_existing:
				pass
				# Reuse row
				row = buy_list.get_child(idx + 1)
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
				buy_list.add_child(row)
		elif idx < num_existing:
			buy_list.get_child(idx + 1).queue_free()

	restore_list_focus(buy_list, last_focused_item_id)

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
		# After the purchase, update the UI
		populate_buy_items(last_items_with_stock)
		# If no enabled buy buttons left, return to menu
		if not _has_enabled_buy_buttons():
			_show_menu()

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
		for idx in range(1, buy_list.get_child_count()):
			var row = buy_list.get_child(idx)
			var btn = row.get_child(0)
			if btn.get_meta("item_id") == last_focused_item_id and not btn.disabled:
				button_to_focus = btn
				break
		if button_to_focus == null:
			# Fallback to the first enabled buy button
			for idx in range(1, buy_list.get_child_count()):
				var row = buy_list.get_child(idx)
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
	for i in range(1, buy_list.get_child_count()):
		var row = buy_list.get_child(i)
		var btn = row.get_child(0)
		btn.focus_mode = Control.FOCUS_ALL if itemlist_enabled else Control.FOCUS_NONE

# Populate the sell list with player's inventory
func populate_sell_items(inventory_dict: Dictionary) -> void:
	#DEBUG print("ShopUI.gd/populate_sell_items() called")
	# Remove previous entries (from last to first to avoid skipping)
	for i in range(sell_list.get_child_count() - 1, 0, -1):
		sell_list.get_child(i).queue_free()

	var num_items = 0
	for item_id in inventory_dict.keys():
		var count = inventory_dict[item_id]
		if count <= 0:
			continue

		var item = Item.get_item(item_id)
		if item == null:
			continue

		num_items += 1

		var sell_price = int(item.price * Item.SELL_PERCENT)
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var item_label = Button.new()
		item_label.text = item.name
		item_label.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_label.custom_minimum_size.x = 100
		item_label.focus_mode = Control.FOCUS_ALL
		item_label.set_meta("item_id", item.id)
		row.add_child(item_label)

		var qty_label = Label.new()
		qty_label.custom_minimum_size.x = 35
		qty_label.text = str(count)
		row.add_child(qty_label)

		var price_label = Label.new()
		price_label.custom_minimum_size.x = 35
		price_label.text = str(sell_price)
		row.add_child(price_label)

		item_label.connect("focus_entered", Callable(self, "_on_sell_button_focus_entered").bind(item_id))
		item_label.connect("pressed", Callable(self, "_on_sell_button_pressed").bind(item_id))
		sell_list.add_child(row)

	#DEBUG print("populate_sell_items: num_items=", num_items, " sell_list children count: ", sell_list.get_child_count())

	if num_items == 0:
		#DEBUG print("No sellable items left, switching to menu.")
		_show_menu()
	else:
		#DEBUG print("Restoring focus in sell_list. Last focused: ", last_focused_sell_item_id)
		await _restore_sell_list_focus_async(sell_list, last_focused_sell_item_id)
	#DEBUG print("Focus owner after populating sell items: ", get_viewport().gui_get_focus_owner())

func _on_sell_pressed():
	#DEBUG print("ShopUI.gd/_on_sell_pressed() called")
	shop_mode = "sell"
	set_menu_focus_enabled(false, true)
	populate_sell_items(PlayerInventory.items)
	buy_list.visible = false
	buy_header_row.visible = false
	sell_list.visible = true
	sell_header_row.visible = true
	shop_cursor.visible = true
	#DEBUG print("ShopUI.gd/_on_sell_pressed() -> shop_cursor.visible = true")

func _on_sell_button_pressed(item_id):
	var quantity = PlayerInventory.items.get(item_id, 0)
	#DEBUG print("Quantity before selling: ", quantity)
	if quantity > 0:
		var item = Item.get_item(item_id)
		var sell_price = int(item.price * Item.SELL_PERCENT)
		PlayerInventory.money += sell_price
		PlayerInventory.items[item_id] -= 1
		if PlayerInventory.items[item_id] <= 0:
			PlayerInventory.items.erase(item_id)
			# If the current item is sold out, pick the next available item for focus
			last_focused_sell_item_id = _get_next_sell_item_id(item_id)
		populate_sell_items(PlayerInventory.items)
		#DEBUG print("Called populate_sell_items after selling")
		#DEBUG print("Focus owner after selling: ", get_viewport().gui_get_focus_owner())
		#DEBUG print("get_tree().paused: ", get_tree().paused)

func _on_sell_button_focus_entered(item_id):
	#DEBUG print("ShopUI.gd/_on_sell_button_focus_entered() called")
	last_focused_sell_item_id = item_id
	var item = Item.get_item(item_id)
	emit_signal("item_selected", item)
	detail_label.text = item.description + " : " + item.type

func _focus_sell_button_async(button: Button) -> void:
	await get_tree().process_frame # Wait until the next frame
	if button.is_inside_tree() and button.visible and not button.disabled:
		button.grab_focus()
		#DEBUG print("Focused button after frame: ", button)
	else:
		print("Button not ready for focus after frame: ", button)

# Helper to get the next available item_id after the current one is removed
func _get_next_sell_item_id(current_id):
	var keys = PlayerInventory.items.keys()
	if keys.size() == 0:
		return ""
	var idx = keys.find(current_id)
	if idx == -1 or keys.size() == 1:
		return keys[0]
	elif idx < keys.size() - 1:
		return keys[idx + 1]
	else:
		return keys[0]

func _on_exit_pressed():
	close()

func restore_list_focus(list: VBoxContainer, last_focused_item_id: String, skip_header := true):
	var start_idx = 1 if skip_header else 0
	var button_to_focus: Button = null

	for idx in range(start_idx, list.get_child_count()):
		var row = list.get_child(idx)
		if row.get_child_count() == 0:
			continue
		var btn = row.get_child(0)
		#DEBUG print("Checking button: ", btn, " with id: ", btn.get_meta("item_id"), " disabled: ", btn.disabled)
		if btn.has_meta("item_id") and btn.get_meta("item_id") == last_focused_item_id and not btn.disabled:
			button_to_focus = btn
			break

	if button_to_focus == null:
		for idx in range(start_idx, list.get_child_count()):
			var row = list.get_child(idx)
			if row.get_child_count() == 0:
				continue
			var btn = row.get_child(0)
			if not btn.disabled:
				button_to_focus = btn
				break

	if button_to_focus:
		if button_to_focus.focus_mode == Control.FOCUS_NONE:
			button_to_focus.focus_mode = Control.FOCUS_ALL
		button_to_focus.grab_focus()
		#DEBUG print("Focused button: ", button_to_focus)
	else:
		exit_button.grab_focus()
		#DEBUG print("No valid button found, focused exit_button")

func _restore_sell_list_focus_async(list: VBoxContainer, last_focused_item_id: String, skip_header := true) -> void:
	var start_idx = 1 if skip_header else 0
	var button_to_focus: Button = null

	for idx in range(start_idx, list.get_child_count()):
		var row = list.get_child(idx)
		if row.get_child_count() == 0:
			continue
		var btn = row.get_child(0)
		if btn.has_meta("item_id") and btn.get_meta("item_id") == last_focused_item_id and not btn.disabled:
			button_to_focus = btn
			break

	if button_to_focus == null:
		for idx in range(start_idx, list.get_child_count()):
			var row = list.get_child(idx)
			if row.get_child_count() == 0:
				continue
			var btn = row.get_child(0)
			if not btn.disabled:
				button_to_focus = btn
				break

	await get_tree().process_frame # <--- This is the key!
	if button_to_focus and button_to_focus.is_inside_tree() and button_to_focus.visible and not button_to_focus.disabled:
		button_to_focus.grab_focus()
		#DEBUG print("Focused sell button after frame: ", button_to_focus)
	else:
		exit_button.grab_focus()
		#DEBUG print("Fallback to exit_button focus after frame")
