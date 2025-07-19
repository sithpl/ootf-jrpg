class_name BattleActor extends Resource

# Signals
signal hp_changed(hp, change)
signal defeated()
signal acting()

# Variables
var class_key     :String      = ""
var attack_anim   :String      = ""
var death_anim    :String      = ""

var name          :String      = "Not Set"
var lvl           :int         = 0
var gold          :int         = 0
var hp            :int         = hp_max
var hp_max        :int         = 1 
var ap_max        :int         = 0
var ap            :int         = ap_max
var speed         :int         = 1
var strength      :int         = 1
var xp            :int         = 0

var texture       :Texture     = null
var friendly      :bool        = false

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

func set_name_custom(value: String):
	#DEBUG print("BattleActor.gd/set_name_custom() called")
	name = value
	
	if !friendly:
		var name_formatted: String = name.to_lower().replace(" ", "_")
		texture = load("res://Assets/Enemies/" + name_formatted + ".png")
		#"res://Assets/Enemies/slime_green.png"
		#DEBUG print(name)

func duplicate_custom():
	#DEBUG print("BattleActor.gd/duplicate_custom() called")
	var dup := BattleActor.new(xp, gold, hp_max, ap_max, speed, strength)
	dup.copy_from(self)
	dup.set_name_custom(name) # <- triggers texture loading for enemies
	dup.resource_name = name
	print(name, " : ", xp)
	return dup

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

func has_hp():
	print("BattleActor.gd/has_hp() called")
	return hp > 0

func can_act():
	print("BattleActor.gd/can_act() called")
	return has_hp()

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

func act():
	print("BattleActor.gd/act() called")
	acting.emit()

#func set_attack_anim(val:String):
	#attack_anim = val
	#print("BattleActor attack_anim set to:", attack_anim)
