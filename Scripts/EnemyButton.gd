class_name EnemyButton extends BattleActorButton

func _ready():
	# TODO load data based on overworld tile/cohort
	pass

func _on_data_is_defeated():
	print("EnemyButton.gd/_on_data_is_defeated() called")
	await get_tree().create_timer(1.0).timeout
	queue_free()
