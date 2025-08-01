class_name Item extends Resource

# Item properties
@export var id            :String
@export var name          :String
@export var description   :String
@export var price         :int
@export var type          :String
@export var icon          :Texture2D

@export var use_effect    :String     = ""
@export var use_amount    :int        = 0   
@export var bonuses       :Dictionary = {} # {"ATK": 2}

@export var two_handed: bool = false

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
	ALL_ITEMS["old_sword"]            = Item.new().update("old_sword", "Old Sword", 100, "A dull, mostly decorative blade.", "M.Hand")
	ALL_ITEMS["old_sword"].bonuses    = {"attack": 3}
	
	ALL_ITEMS["iron_sword"]            = Item.new().update("iron_sword", "Iron Sword", 250, "The adventurer classic.", "M.Hand")
	ALL_ITEMS["iron_sword"].bonuses    = {"attack": 5}
	
	ALL_ITEMS["wooden_shield"]            = Item.new().update("wooden_shield", "Wooden Shield", 120, "A large piece of bark with a handle.", "O.Hand")
	ALL_ITEMS["wooden_shield"].bonuses    = {"defense": 2}
	
	ALL_ITEMS["leather_helmet"]            = Item.new().update("leather_helmet", "Leather Helmet", 75, "Protects your head...kind of.", "Head")
	ALL_ITEMS["leather_helmet"].bonuses    = {"defense": 1, "speed": 1}
	
	ALL_ITEMS["worn_chainmail"]            = Item.new().update("worn_chainmail", "Worn Chainmail", 75, "Bigger holes than normal.", "Chest")
	ALL_ITEMS["worn_chainmail"].bonuses    = {"defense": 3}
	
	ALL_ITEMS["long_stick"]            = Item.new().update("long_stick", "Long Stick (2H)", 75, "That's a nice stick.", "M.Hand")
	ALL_ITEMS["long_stick"].bonuses    = {"attack": 2, "magic": 5}
	ALL_ITEMS["long_stick"].two_handed  = true
	
	ALL_ITEMS["worn_bow"]             = Item.new().update("worn_bow", "Worn Bow (2H)", 275, "The string is a little loose.", "M.Hand")
	ALL_ITEMS["worn_bow"].bonuses     = {"attack": 4, "speed": 4}
	ALL_ITEMS["worn_bow"].two_handed  = true
	
	ALL_ITEMS["linen_robes"]            = Item.new().update("linen_robes", "Linen Robes", 100, "That's a nice stick.", "Chest")
	ALL_ITEMS["linen_robes"].bonuses    = {"defense": 1, "magic": 1}
	
	ALL_ITEMS["goodsword"]             = Item.new().update("goodsword", "Goodsword (2H)", 500, "Not quite great...", "M.Hand")
	ALL_ITEMS["goodsword"].bonuses     = {"attack": 10}
	ALL_ITEMS["goodsword"].two_handed  = true
	
	ALL_ITEMS["shiv"]            = Item.new().update("shiv", "Shiv", 100, "Good for shanking snitches.", "O.Hand")
	ALL_ITEMS["shiv"].bonuses    = {"attack": 3}
	
	ALL_ITEMS["potion"]               = Item.new().update("potion", "Potion", 10, "Heals 50 HP", "Consume")
	ALL_ITEMS["potion"].use_effect    = "heal"
	ALL_ITEMS["potion"].use_amount    = 50
	
	ALL_ITEMS["antidote"]             = Item.new().update("antidote", "Antidote", 25, "Cures poison", "Consume")
	ALL_ITEMS["antidote"].use_effect  = "cure_poison"

	ALL_ITEMS["ether"]                = Item.new().update("ether", "Ether", 50, "Restores 20 AP", "Consume")
	ALL_ITEMS["ether"].use_effect     = "restore_ap"
	ALL_ITEMS["ether"].use_amount     = 20
	# Add more items as needed

# Return the item with the given id
static func get_item(id: String) -> Item:
	return ALL_ITEMS.get(id)

func use(target):
	if use_effect != "":
		Effects.apply_effect(use_effect, target, [use_amount] if use_amount != 0 else [])
