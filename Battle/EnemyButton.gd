class_name EnemyButton extends BattleActorButton

@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Called when EnemyButton is added to the scene
func _ready():
	# TODO: Load data based on overworld tile/cohort if needed
	pass

# Handles what happens when this enemy is defeated
func _on_data_is_defeated():
	#DEBUG print("EnemyButton.gd/_on_data_is_defeated() called")
	if anim_player:
		await get_tree().create_timer(1.0).timeout
		anim_player.play("enemy_death")
		await anim_player.animation_finished
	else:
		print("AnimationPlayer is nil!")  # Wait briefly for animation, etc.
	await get_tree().create_timer(0.5).timeout
	queue_free()  # Remove enemy button from scene
