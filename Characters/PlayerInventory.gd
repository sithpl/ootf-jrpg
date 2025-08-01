extends Node

signal money_changed

# Stores items by item_id and count
var items := {"potion": 5, "ether": 3, "antidote": 2, "old_sword": 1, "wooden_shield": 1,"leather_helmet": 1, "worn_chainmail": 1} # {item_id: count}
var money = 2000 # TODO Implement money system

# Example: {"Cracker": {"M.Hand": "old_sword", ...}, ...}
var equipment := {}

# Print inventory at startup
func ready():
	print_inventory()

func add_money(amount):
	money += amount
	emit_signal("money_changed")

# Clear inventory and print
func clear():
	items.clear()
	print_inventory()

# Print inventory contents to output
func print_inventory():
	print("---- Player Inventory ----")
	if items.size() == 0:
		print("Inventory is empty.")
	else:
		for item_id in items.keys():
			print("%s: %d" % [item_id, items[item_id]])
	print("-------------------------")

# ---------- ALL ITEMS ----------

# Add item(s) to inventory and print
func add_item(item_id: String, amount: int = 1):
	if items.has(item_id):
		items[item_id] += amount
	else:
		items[item_id] = amount
	print_inventory()

# Remove item(s) from inventory and print
func remove_item(item_id: String, amount: int = 1):
	print("PlayerInventory.gd/remove_item() called")
	if items.has(item_id):
		items[item_id] -= amount
		if items[item_id] <= 0:
			items.erase(item_id)
	print_inventory()

# Check if inventory has at least 'amount' of item_id
func has_item(item_id: String, amount: int = 1) -> bool:
	return items.has(item_id) and items[item_id] >= amount

# Get count of a specific item
func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)

# Get all items as array of dictionaries
func get_all_items() -> Array:
	var result := []
	for id in items.keys():
		result.append({"item_id": id, "count": items[id]})
	return result

# ---------- EQUIPMENT ----------

func equip_item(name: String, slot: String, item_id: String) -> void:
	var eq = get_equipment_for(name)
	eq[slot] = item_id
	set_equipment_for(name, eq)

func get_equipment_for(name: String) -> Dictionary:
	if equipment.has(name):
		return equipment[name].duplicate()
	# Return empty equipment slots for new characters
	return {"M.Hand": null, "O.Hand": null, "Head": null, "Chest": null}

func set_equipment_for(name: String, equipment: Dictionary) -> void:
	equipment[name] = equipment.duplicate()

func apply_equipment_bonuses(actor, equipment: Dictionary) -> void:
	if not equipment:
		return
	for slot in equipment.keys():
		var item_id = equipment[slot]
		if item_id:
			var item = Item.get_item(item_id)
			if item and item.bonuses:
				for stat in item.bonuses.keys():
					match stat:
						"attack":
							actor.attack += item.bonuses[stat]
						"defense":
							actor.defense += item.bonuses[stat]
						"magic":
							actor.magic += item.bonuses[stat]
						"speed":
							actor.speed += item.bonuses[stat]
						"base_hp", "hp_max":
							actor.hp_max += item.bonuses[stat]
						"base_ap", "ap_max":
							actor.ap_max += item.bonuses[stat]
						_:
							# If you add custom fields, handle them here
							pass
