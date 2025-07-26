class_name Shopkeeper extends Node2D

@export var shop_id: String
@export var shop_anim: String
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shopui : ShopUI = $CanvasLayer/ShopUI

const SHOPUI : PackedScene = preload("res://GUI/ShopUI.tscn")

var dialogue_index := 0
var shop_can_interact = false

# All NPC data in one dictionary, now with inventory as {item_id: stock}
var shop_database := {
	"armory": {
		"name": "Tammy",
		"default_dialogue": ["What are ya' buyin'?", ""],
		"hoegetter_dialogue": {},
		"portrait": "res://Assets/Portraits/alice.png",
		"animation_set": "female_villager_1",
		"inventory": {
			"iron_sword": 1,
			"steel_shield": 2,
			"helmet": 1
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

func interact():
	show_greeting_dialogue()

func show_greeting_dialogue():
	MusicManager.interact()
	Globals.player.movement_locked = true

	var dialogue = get_formatted_dialogue()
	TextUi.show_dialogue_box(dialogue)

	await TextUi.confirmed

	TextUi.hide_dialogue_box()
	Globals.player.movement_locked = false
	_on_greeting_finished()

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

func get_formatted_dialogue() -> String:
	var name = shop_database.get(shop_id, {}).get("name", "???")
	var line = get_dialogue()
	return "%s: %s" % [name, line]

func _on_greeting_finished():
	show_buy_sell_menu()

func show_buy_sell_menu():
	# Get shop's inventory dict from shop_database
	var inventory_dict := {}
	if shop_database.has(shop_id):
		inventory_dict = shop_database[shop_id].get("inventory", {})

	# Map inventory IDs to actual Item resources using ItemDatabase (must be autoloaded singleton)
	# Build an array of {item: Item, stock: int}
	var items_with_stock := []
	for item_id in inventory_dict.keys():
		var item = Item.get_item(item_id)
		if item:
			items_with_stock.append({"item": item, "stock": inventory_dict[item_id]})

	shopui.populate_items(items_with_stock) # ShopUI must support this format
	shopui.open()

func hide_buy_sell_menu():
	shopui.close()

func change_stock(item_id: String, delta: int):
	print("Shopkeeper.gd/change_stock() called")
	if shop_database.has(shop_id):
		var inventory = shop_database[shop_id].get("inventory", {})
		if inventory.has(item_id):
			inventory[item_id] += delta
			if inventory[item_id] <= 0:
				inventory.erase(item_id)
		elif delta > 0:
			# Add new item to inventory if adding stock
			inventory[item_id] = delta
		# Save back to shop_database
		shop_database[shop_id]["inventory"] = inventory

# Called whenever an item is purchased from the shop UI
func _on_item_purchased(item: Item, amount: int):
	print("Shopkeeper.gd/on_item_purchased() called")
	# Reduce shop inventory
	var inventory_dict = shop_database[shop_id].get("inventory", {})
	var item_id = item.id  # Or however you uniquely identify the item
	if inventory_dict.has(item_id):
		inventory_dict[item_id] -= amount
		if inventory_dict[item_id] <= 0:
			inventory_dict.erase(item_id)
		shop_database[shop_id]["inventory"] = inventory_dict

	# Add to player inventory (you may need to adjust this for your player inventory system)
	PlayerInventory.add_item(item.id, amount)

	# Optionally adjust player money here (e.g., Globals.player.money -= item.price * amount)
	# Optionally play a sound, show a confirmation, etc.

	# Refresh the shop UI to show updated stock
	show_buy_sell_menu()

# Optionally handle item selection (focus) for side-panel details or description
func _on_item_selected(item: Item):
	print("Shopkeeper.gd/on_item_selected() called")
	# Example: Show item details in a side-panel or popup
	# $ItemDescriptionLabel.text = item.description
	pass

func set_spawn_direction(direction: String):
	if shop_animations.has(shop_anim):
		var anim_name = shop_animations[shop_anim].get(direction, "")
		if anim_name != "":
			animated_sprite.set_animation(anim_name)

func _on_interaction_range_body_entered(body):
	if body.is_in_group("player"):
		shop_can_interact = true

func _on_interaction_range_body_exited(body):
	if body.is_in_group("player"):
		shop_can_interact = false

func _unhandled_input(event):
	if shop_can_interact and event.is_action_pressed("ui_accept"):
		var shop_ui = find_child("ShopUI", true, false)
		if shop_ui:
			show_greeting_dialogue()
		else:
			print("ShopUI node not found!")

	if shopui.visible and event.is_action_pressed("ui_cancel"):
		hide_buy_sell_menu()
