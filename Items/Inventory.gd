class_name Inventory extends Node 

# Dictionary to store {item_id: count}
@export var items := {}

# Add an item to the inventory, stacking by item_id
func add_item(item_id: String, amount: int = 1):
	if items.has(item_id):
		items[item_id] += amount
	else:
		items[item_id] = amount

# Remove an item from the inventory, decrease count or erase if zero
func remove_item(item_id: String, amount: int = 1):
	if items.has(item_id):
		items[item_id] -= amount
		if items[item_id] <= 0:
			items.erase(item_id)

# Check if the inventory has at least 'amount' of an item
func has_item(item_id: String, amount: int = 1) -> bool:
	return items.has(item_id) and items[item_id] >= amount

# Get the count of a specific item
func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)

# Get array of all items [{item_id: String, count: int}, ...]
func get_all_items() -> Array:
	var result := []
	for id in items.keys():
		result.append({"item_id": id, "count": items[id]})
	return result

# Optional: Clear inventory
func clear():
	items.clear()
