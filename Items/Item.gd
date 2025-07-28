class_name Item extends Resource

# Item properties
@export var id: String
@export var name: String
@export var description: String
@export var price: int
@export var type: String # For use later
@export var icon: Texture2D

const SELL_PERCENT := 0.5

# Stores all registered items by id
static var ALL_ITEMS := {}

# Update item fields and return self
func update(new_id, n, p, d, t):
	id = new_id
	name = n
	price = p
	description = d
	type = t
	return self

# Register all items in the static ALL_ITEMS dict
static func register_items():
	ALL_ITEMS.clear()
	ALL_ITEMS["old_sword"]      = Item.new().update("old_sword", "Old Sword", 100, "A dull, mostly decorative blade.", "M.Hand")
	ALL_ITEMS["wooden_shield"]  = Item.new().update("wooden_shield", "Wooden Shield", 120, "A large piece of bark with a handle.", "O.Hand")
	ALL_ITEMS["leather_helmet"] = Item.new().update("leather_helmet", "Leather Helmet", 75, "Protects your head...kind of.", "Head")
	ALL_ITEMS["worn_chainmail"] = Item.new().update("worn_chainmail", "Worn Chainmail", 75, "Bigger holes than normal.", "Chest")
	ALL_ITEMS["potion"]         = Item.new().update("potion", "Potion", 10, "Heals 50 HP", "Consume")
	ALL_ITEMS["antidote"]       = Item.new().update("antidote", "Antidote", 25, "Cures poison", "Consume")
	ALL_ITEMS["ether"]          = Item.new().update("ether", "Ether", 50, "Restores 20 MP", "Consume")
	# Add more items as needed

# Return the item with the given id
static func get_item(id: String) -> Item:
	return ALL_ITEMS.get(id)
