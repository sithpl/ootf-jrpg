class_name BattleActor extends Resource

# Signals
signal hp_changed(hp, change)              # Notify when HP changes
signal defeated()                          # Notify when actor is defeated
signal acting()                            # Notify when actor is acting

var last_attempted_damage: int = 0

# ---------- Actor Properties ----------

var class_key     :String      = ""        # Class type (e.g. "Soldier", "Mage")
var attack_anim   :String      = ""        # Name of attack animation
var death_anim    :String      = ""        # Name of death animation

var name          :String      = "Not Set" # Display name
var lvl           :int         = 0         # Level
var gold          :int         = 0         # Gold
var base_hp       :int         = hp_max    # Current HP
var hp_max        :int         = 1         # Max HP
var base_ap       :int         = ap_max    # Current AP
var ap_max        :int         = 0         # Max AP (Action Points)
var attack        :int         = 1         
var defense       :int         = 1         
var magic         :int         = 1         
var speed         :int         = 1         # Turn order speed
var xp            :int         = 0         # EXP

var texture       :Texture     = null      # Sprite/texture for UI
var friendly      :bool        = false     # Is this a player character?

# ---------- Actor Initialization ----------

# Sets up actor stats at creation
func _init(_lvl: int, _gold: int, _hp: int = base_hp, _ap: int = base_ap, _attack : int = attack, _defense: int = defense, _magic: int = magic, _speed: int = speed):
	#DEBUG print("BattleActor.gd/_init() called")
	lvl = _lvl
	gold = _gold
	hp_max = _hp
	base_hp = _hp
	ap_max = _ap
	base_ap = _ap
	attack = _attack
	defense = _defense
	magic = _magic
	speed = _speed
	xp = lvl * 5

# Set the actor's name, and loads texture for enemies
func set_name_custom(value: String):
	#DEBUG print("BattleActor.gd/set_name_custom() called")
	name = value
	
	if !friendly:
		var name_formatted: String = name.to_lower().replace(" ", "_")
		texture = load("res://Assets/Enemies/" + name_formatted + ".png")
		#"res://Assets/Enemies/slime_green.png"
		#DEBUG print(name)

# Create a copy of this actor, including stats and texture
func duplicate_custom():
	#DEBUG print("BattleActor.gd/duplicate_custom() called")
	var dup := BattleActor.new(xp, gold, base_hp, base_ap, attack, defense, magic, speed)
	dup.copy_from(self)
	dup.set_name_custom(name) # <- triggers texture loading for enemies
	dup.resource_name = name
	print(name, " : ", xp)
	return dup

# Copy all properties from another BattleActor
func copy_from(source: BattleActor):
	#DEBUG print("BattleActor.gd/copy_from() called")
	name = source.name
	hp_max = source.hp_max
	base_hp = source.base_hp
	ap_max = source.ap_max
	base_ap = source.base_ap
	attack = source.attack
	defense = source.defense
	magic = source.magic
	speed = source.speed
	xp = source.xp
	gold = source.gold
	texture = source.texture
	friendly = source.friendly

# ---------- State/Logic ----------

# Returns true if actor has HP left
func has_hp():
	#DEBUG print("BattleActor.gd/has_hp() called")
	return base_hp > 0

# Returns true if actor can act (alive)
func can_act():
	#DEBUG print("BattleActor.gd/can_act() called")
	return has_hp()

# Heal or damage actor by value; emits hp_changed, defeated if killed
func healhurt(value: int):
	#DEBUG print("BattleActor.gd/healhurt() called")
	last_attempted_damage = value  # Store the attempted value
	#DEBUG print("Damage: ", value)
	var hp_start: int = base_hp
	var change: int = 0
	base_hp += value
	base_hp = clamp(base_hp, 0, hp_max)
	change = base_hp - hp_start
	emit_signal("hp_changed", base_hp, change)
	hp_changed.emit(base_hp, change)
	if !has_hp():
		defeated.emit()

# Emits the acting signal for animation/feedback
func act():
	#DEBUG print("BattleActor.gd/act() called")
	acting.emit()

# Heal HP
func heal(amount: int):
	healhurt(amount)
	print("%s healed by %d, now at %d/%d HP" % [name, amount, base_hp, hp_max])

# Restore AP 
func restore_ap(amount: int):
	base_ap += amount
	base_ap = clamp(base_ap, 0, ap_max)
	print("%s restored %d AP, now at %d/%d AP" % [name, amount, base_ap, ap_max])

# Cure poison
func cure_poison():
	# If you track status effects, clear poison here
	print("%s is cured of poison!" % name)

# Revive with 50%
func revive(percent: float = 0.5):
	if base_hp <= 0:
		base_hp = int(hp_max * percent)
		emit_signal("hp_changed", base_hp, base_hp)
		print("%s revived to %d/%d HP!" % [name, base_hp, hp_max])
