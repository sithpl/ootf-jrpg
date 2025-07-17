class_name PlayerInfoBar extends HBoxContainer

#signal atb_ready()

@onready var data: BattleActor = Data.party[get_index()]
@onready var _name: Label = $Name
@onready var _health: Label = $Health
@onready var _mana: Label = $Mana
#@onready var _atb : ATBBar = $ATBBar
@onready var _anim : AnimationPlayer = $AnimationPlayer

func _ready():
	_anim.play("RESET")
	_name.text = data.name
	_health.text = str(data.hp)
	_mana.text = str(data.mp)
	data.hp_changed.connect(_on_data_hp_changed)

func _on_data_hp_changed(hp: int, _change: int):
	_health.text = str(hp)
	if hp == 0:
		modulate = Color.DARK_RED
		#_atb.reset()
		#_atb.stop()

func highlight(on: bool = true):
	var anim: String = "highlight" if on else "RESET"
	_anim.play(anim)

#func reset():
	#_atb.reset()
#
#func stop():
	#_atb.stop()
#
#func _on_atb_bar_filled():
	#atb_ready.emit()
