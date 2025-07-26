extends Resource
class_name Item

@export var id: String
@export var name: String
@export var description: String
@export var price: int
@export var icon: Texture2D

static var ALL_ITEMS := {}

# Building items
func update(new_id, n, p, d):
	id = new_id
	name = n
	price = p
	description = d
	return self

# Static method to register all items
static func register_items():
	ALL_ITEMS.clear()
	ALL_ITEMS["iron_sword"]   = Item.new().update("iron_sword", "Sword", 100, "A sharp blade")
	ALL_ITEMS["steel_shield"] = Item.new().update("steel_shield", "Shield", 120, "Sturdy shield")
	ALL_ITEMS["helmet"]       = Item.new().update("helmet", "Helmet", 75, "Protects your head")
	ALL_ITEMS["potion"]       = Item.new().update("potion", "Potion", 10, "Heals 50 HP")
	ALL_ITEMS["antidote"]     = Item.new().update("antidote", "Antidote", 25, "Cures poison")
	ALL_ITEMS["ether"]        = Item.new().update("ether", "Ether", 50, "Restores 20 MP")
	# Add more items as needed

# Static method to fetch an item by ID
static func get_item(id: String) -> Item:
	return ALL_ITEMS.get(id)
	print(id)
