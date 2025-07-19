class_name BattleActor extends Resource

# Signals
signal hp_changed(hp, change)              # Notify when HP changes
signal defeated()                          # Notify when actor is defeated
signal acting()                            # Notify when actor is acting

# ---------- Actor Properties ----------

var class_key     :String      = ""        # Class type (e.g. "Soldier", "Mage")
var attack_anim   :String      = ""        # Name of attack animation
var death_anim    :String      = ""        # Name of death animation

var name          :String      = "Not Set" # Display name
var lvl           :int         = 0         # Level
var gold          :int         = 0         # Gold
var hp            :int         = hp_max    # Current HP
var hp_max        :int         = 1         # Max HP
var ap_max        :int         = 0         # Max AP (Action Points)
var ap            :int         = ap_max    # Current AP
var speed         :int         = 1         # Turn order speed
var strength      :int         = 1         # Physical power
var xp            :int         = 0         # EXP

var texture       :Texture     = null      # Sprite/texture for UI
var friendly      :bool        = false     # Is this a player character?

# ---------- Actor Initialization ----------

# Sets up actor stats at creation
func _init(_lvl: int, _gold: int,_hp: int = hp_max, _ap: int = ap_max, _speed: int = speed, _strength: int = strength):
	#DEBUG print("BattleActor.gd/_init() called")
	lvl = _lvl
	gold = _gold
	hp_max = _hp
	hp = _hp
	ap_max = _ap
	ap = _ap
	strength = _strength
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
	var dup := BattleActor.new(xp, gold, hp_max, ap_max, speed, strength)
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
	hp = source.hp
	ap_max = source.ap_max
	ap = source.ap
	speed = source.speed
	strength = source.strength
	xp = source.xp
	gold = source.gold
	texture = source.texture
	friendly = source.friendly

# ---------- State/Logic ----------

# Returns true if actor has HP left
func has_hp():
	print("BattleActor.gd/has_hp() called")
	return hp > 0

# Returns true if actor can act (alive)
func can_act():
	print("BattleActor.gd/can_act() called")
	return has_hp()

# Heal or damage actor by value; emits hp_changed, defeated if killed
func healhurt(value: int):
	print("BattleActor.gd/healhurt() called")
	#DEBUG print("Damage: ", value)
	var hp_start: int = hp
	var change: int = 0
	hp += value
	hp = clamp(hp, 0, hp_max)
	change = hp - hp_start
	emit_signal("hp_changed", hp, change)
	hp_changed.emit(hp, change)
	if !has_hp():
		defeated.emit()

# Emits the acting signal for animation/feedback
func act():
	print("BattleActor.gd/act() called")
	acting.emit()

#func set_attack_anim(val:String):
	#attack_anim = val
	#print("BattleActor attack_anim set to:", attack_anim)
