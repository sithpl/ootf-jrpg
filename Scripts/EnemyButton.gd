class_name EnemyButton extends BattleActorButton

signal atb_ready()

@onready var _atb_bar: ATBBar = $ATBBar

func _ready():
	# TODO load data based on overworld tile/cohort
	set_data(Data.enemies.Goofball.duplicate_custom())

func reset():
	_atb_bar.reset()

func _on_atb_bar_filled() -> void:
	atb_ready.emit()
	#_atb_bar.reset()

func _on_data_is_defeated():
	print("Enemy defeated")
	_atb_bar.stop()
	await get_tree().create_timer(1.0).timeout
	queue_free()
