class_name PlayerInfoBar extends HBoxContainer

# Onreadys
@onready var data      :BattleActor       = Data.party[get_index()]   # The BattleActor for this party slot
@onready var _name     :Label             = $Name                     # Label node displaying player's name
@onready var _health   :Label             = $Health                   # Label node displaying player's HP
@onready var _action   :Label             = $Mana                     # Label node displaying player's AP (Action Points)
@onready var _anim     :AnimationPlayer   = $AnimationPlayer          # AnimationPlayer for UI effects

# Called when the info bar is ready (scene instanced)
func _ready():
	_anim.play("RESET")                 # Reset UI animations
	_name.text = data.name              # Set name label
	_health.text = str(data.base_hp)         # Set health label
	_action.text = str(data.base_ap)         # Set AP label
	
	data.hp_changed.connect(_on_data_hp_changed)  # Connect to BattleActor's hp_changed signal
	data.ap_changed.connect(_on_data_ap_changed)  # Connect to BattleActor's ap_changed signal

# Updates health display and highlights when HP changes
func _on_data_hp_changed(hp: int, _change: int):
	#DEBUG print("PlayerInfoBar.gd/_on_data_hp_changed() called")
	_health.text = str(hp)
	if hp == 0:
		modulate = Color.DARK_RED       # Visually indicate the character is defeated

func _on_data_ap_changed(ap: int, _change: int):
	_action.text = str(ap)
