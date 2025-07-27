class_name Shopkeeper extends Node2D

# Exported shop ID and animation set
@export var shop_id: String
@export var shop_anim: String

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shopui : ShopUI = $CanvasLayer/ShopUI
@onready var shop_cursor : ShopCursor = $CanvasLayer/ShopUI/ShopCursor

const SHOPUI : PackedScene = preload("res://GUI/ShopUI.tscn")

var dialogue_index := 0
var shop_can_interact = false

# Shop data, including inventory and dialogues
var shop_database := {
	"armory": {
		"name": "Tammy",
		"default_dialogue": ["What are ya' buyin'?", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/alice.png",
		"animation_set": "female_villager_1",
		"inventory": {
			"old_sword": 2,
			"wooden_shield": 1,
			"leather_helmet": 2
		}
	},
	"items": {
		"name": "Tommy",
		"default_dialogue": ["What are ya' sellin'?", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/bob.png",
		"animation_set": "male_villager_1",
		"inventory": {
			"potion": 10,
			"antidote": 5,
			"ether": 3
		}
	},
}

# Animation settings for shopkeeper types
var shop_animations = {
	"male_villager_1": {
		"move_up": "male_villager_1_UP",
		"move_down": "male_villager_1_DOWN",
		"move_left": "male_villager_1_LEFT",
		"move_right": "male_villager_1_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	"female_villager_1": {
		"move_up": "female_villager_1_UP",
		"move_down": "female_villager_1_DOWN",
		"move_left": "female_villager_1_LEFT",
		"move_right": "female_villager_1_RIGHT",
		"scale": Vector2(1.0, 1.0)
	},
	# Add more sets as needed
}

func _ready():
	Item.register_items()
	shopui.hide()
	shopui.connect("item_purchased", Callable(self, "_on_item_purchased"))
	shopui.connect("item_selected", Callable(self, "_on_item_selected"))

	if shop_database.has(shop_id):
		var data = shop_database[shop_id]
		shop_anim = data.get("animation_set", shop_anim)
		if shop_animations.has(shop_anim):
			animated_sprite.scale = shop_animations[shop_anim].get("scale", Vector2(1, 1))
	set_spawn_direction("move_down")

# Called when player interacts with shopkeeper
func interact():
	show_greeting_dialogue()

# Show greeting and dialogue before opening shop
func show_greeting_dialogue():
	MusicManager.interact()
	Globals.player.movement_locked = true

	var dialogue = get_formatted_dialogue()
	TextUi.show_dialogue_box(dialogue)

	await TextUi.confirmed

	TextUi.hide_dialogue_box()
	Globals.player.movement_locked = false
	_on_greeting_finished()

# Get current dialogue line
func get_dialogue() -> String:
	if not shop_database.has(shop_id):
		return "..."
	var data = shop_database[shop_id]
	var dialogue = data.get("default_dialogue", ["..."])

	if dialogue.size() > 0:
		var dialogue_line = dialogue[dialogue_index]
		dialogue_index = (dialogue_index + 1) % dialogue.size()
		return dialogue_line
	return "..."

# Format dialogue with shopkeeper's name
func get_formatted_dialogue() -> String:
	var name = shop_database.get(shop_id, {}).get("name", "???")
	var line = get_dialogue()
	return "%s: %s" % [name, line]

# After dialogue, show shop menu
func _on_greeting_finished():
	show_buy_sell_menu()

# Show the shop UI with current inventory
func show_buy_sell_menu():
	var inventory_dict := {}
	if shop_database.has(shop_id):
		inventory_dict = shop_database[shop_id].get("inventory", {})

	# Build shop items list for UI
	var items_with_stock := []
	for item_id in inventory_dict.keys():
		var item = Item.get_item(item_id)
		if item:
			items_with_stock.append({"item": item, "stock": inventory_dict[item_id]})

	shopui.populate_buy_items(items_with_stock)
	if not shopui.visible:
		shopui.open()
	else:
		shopui.visible = true
	shopui.open()

# Hide the shop UI
func hide_buy_sell_menu():
	shopui.close()

# Change inventory stock for an item
func change_stock(item_id: String, delta: int):
	if shop_database.has(shop_id):
		var inventory = shop_database[shop_id].get("inventory", {})
		if inventory.has(item_id):
			inventory[item_id] += delta
			if inventory[item_id] <= 0:
				inventory.erase(item_id)
		elif delta > 0:
			inventory[item_id] = delta
		shop_database[shop_id]["inventory"] = inventory

# When player buys an item
func _on_item_purchased(item: Item, amount: int):
	shop_cursor.play_confirm_sound()
	var inventory_dict = shop_database[shop_id].get("inventory", {})
	var item_id = item.id
	if inventory_dict.has(item_id):
		inventory_dict[item_id] -= amount
		if inventory_dict[item_id] <= 0:
			inventory_dict.erase(item_id)
		shop_database[shop_id]["inventory"] = inventory_dict

	PlayerInventory.add_item(item.id, amount)
	# TODO Adjust player money, play sound, etc.

	# Update the item list in the existing UI, remain in BUY mode
	var updated_inventory_dict = shop_database[shop_id].get("inventory", {})
	var updated_items_with_stock := []
	for updated_item_id in updated_inventory_dict.keys():
		var updated_item = Item.get_item(updated_item_id)
		if updated_item:
			updated_items_with_stock.append({"item": updated_item, "stock": updated_inventory_dict[updated_item_id]})
	shopui.populate_buy_items(updated_items_with_stock)

# When player selects an item in the shop
func _on_item_selected(item: Item):
	pass

# Set the shopkeeper facing direction/animation
func set_spawn_direction(direction: String):
	if shop_animations.has(shop_anim):
		var anim_name = shop_animations[shop_anim].get(direction, "")
		if anim_name != "":
			animated_sprite.set_animation(anim_name)

# Player enters shop interaction area
func _on_interaction_range_body_entered(body):
	if body.is_in_group("player"):
		shop_can_interact = true

# Player leaves shop interaction area
func _on_interaction_range_body_exited(body):
	if body.is_in_group("player"):
		shop_can_interact = false

# Handle input for shop interaction and closing
func _unhandled_input(event):
	if shop_can_interact and event.is_action_pressed("ui_accept"):
		var shop_ui = find_child("ShopUI", true, false)
		if shop_ui:
			show_greeting_dialogue()
		else:
			print("ShopUI node not found!")

	if shopui.visible and event.is_action_pressed("ui_cancel"):
		hide_buy_sell_menu()
