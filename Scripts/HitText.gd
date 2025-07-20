extends Label

const SPEED   :float   = 0.05   # Speed at which the hit text floats upward

# Every frame, move the hit text upward to create a float/fade effect
func _process(_delta: float):
	position.y -= SPEED

# Called when free timeout triggers, removes hit text from scene
func _on_free_timeout() -> void:
	queue_free()
