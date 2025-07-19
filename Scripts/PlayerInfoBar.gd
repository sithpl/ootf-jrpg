class_name PlayerInfoBar extends HBoxContainer

# Onreadys 
@onready var data: BattleActor = Data.party[get_index()]
@onready var _name: Label = $Name
@onready var _health: Label = $Health
@onready var _action: Label = $Mana
@onready var _anim : AnimationPlayer = $AnimationPlayer

func _ready():
	_anim.play("RESET")
	_name.text = data.name
	_health.text = str(data.hp)
	_action.text = str(data.ap)
	data.hp_changed.connect(_on_data_hp_changed)

func _on_data_hp_changed(hp: int, _change: int):
	print("PlayerInfoBar.gd/_on_data_hp_changed() called")
	_health.text = str(hp)
	if hp == 0:
		modulate = Color.DARK_RED

#func highlight(on: bool = true): # TODO Remove, old animation for taking damage
	#print("PlayerInfoBar.gd/highlight() called")
	#var anim: String = "highlight" if on else "RESET"
	#_anim.play(anim)
