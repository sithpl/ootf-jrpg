class_name EnemyButton extends BattleActorButton

# Called when EnemyButton is added to the scene
func _ready():
	# TODO: Load data based on overworld tile/cohort if needed
	pass

# Handles what happens when this enemy is defeated
func _on_data_is_defeated():
	print("EnemyButton.gd/_on_data_is_defeated() called")
	await get_tree().create_timer(1.0).timeout  # Wait briefly for animation, etc.
	queue_free()  # Remove enemy button from scene
