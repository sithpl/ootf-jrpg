class_name BattleActor extends Resource

signal hp_changed(hp, change)
signal defeated()
signal acting()

var class_key: String = ""
var name: String = "Not Set"
var hp_max: int = 1 
var hp: int = hp_max
var mp_max: int = 0
var mp: int = mp_max
var speed: int = 1
var strength: int = 1
var xp: int = 0
var gold: int = 0
var texture: Texture = null
var friendly: bool = false

func _init(_xp: int, _gold: int,_hp: int = hp_max, _mp: int = mp_max, _speed: int = speed, _strength: int = strength):
	hp_max = _hp
	hp = _hp
	mp_max = _mp
	mp = _mp
	strength = _strength
	speed = _speed
	xp = _xp
	gold = _gold

func set_name_custom(value: String):
	name = value
	
	if !friendly:
		var name_formatted: String = name.to_lower().replace(" ", "_")
		texture = load("res://Assets/Enemies/" + name_formatted + ".png")
		#"res://Assets/Enemies/slime_green.png"
		#DEBUG print(name)

func healhurt(value: int):
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
	acting.emit()

func duplicate_custom():
	var dup := BattleActor.new(xp, gold, hp_max, mp_max, speed, strength)
	dup.copy_from(self)
	dup.set_name_custom(name) # <- triggers texture loading for enemies
	dup.resource_name = name
	return dup

func copy_from(source: BattleActor):
	name = source.name
	hp_max = source.hp_max
	hp = source.hp
	mp_max = source.mp_max
	mp = source.mp
	speed = source.speed
	strength = source.strength
	xp = source.xp
	gold = source.gold
	texture = source.texture
	friendly = source.friendly

func has_hp():
	return hp > 0

func can_act():
	return has_hp()
