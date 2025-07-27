extends Node

# Stores items by item_id and count
var items := {} # {item_id: count}
var money = 2000 # TODO Implement money system

# Print inventory at startup
func ready():
	print_inventory()

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

# Clear inventory and print
func clear():
	items.clear()
	print_inventory()

# TODO Player inventory menu later, for now track via console

# Print inventory contents to output
func print_inventory():
	print("---- Player Inventory ----")
	if items.size() == 0:
		print("Inventory is empty.")
	else:
		for item_id in items.keys():
			print("%s: %d" % [item_id, items[item_id]])
	print("-------------------------")
