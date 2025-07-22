extends Label

const POP_HEIGHT   :float = -16    # How far up the text pops initially
const FALL_HEIGHT  :float = 16     # How far down it falls after popping up
const BOUNCE_COUNT :int   = 2      # Number of bounces after falling
const BOUNCE_HEIGHT:float = 8      # Height of each bounce
const BOUNCE_DECAY :float = 0.2    # Each bounce is shorter

# 30% faster: multiply all durations by 0.7
const POP_TIME     :float = 0.105  # 0.15 * 0.7
const FALL_TIME    :float = 0.126  # 0.18 * 0.7
const BOUNCE_TIME  :float = 0.105  # 0.15 * 0.7
const FADE_TIME    :float = 0.21   # 0.3 * 0.7

@onready var _tween := create_tween()

func _ready():
	# Start at base position
	var start_pos = position
	# 1. Pop up
	_tween.tween_property(self, "position:y", start_pos.y + POP_HEIGHT, POP_TIME).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	# 2. Fall down
	_tween.tween_property(self, "position:y", start_pos.y + FALL_HEIGHT, FALL_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)

	# 3. Bounces
	var bounce_y = start_pos.y + FALL_HEIGHT
	var bounce_height = BOUNCE_HEIGHT
	for i in BOUNCE_COUNT:
		_tween.tween_property(self, "position:y", bounce_y - bounce_height, BOUNCE_TIME * (1.0 - (i * 0.2))).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "position:y", bounce_y, BOUNCE_TIME * (1.0 - (i * 0.2))).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)
		bounce_height *= BOUNCE_DECAY

	# 4. Fade out and queue_free
	_tween.tween_property(self, "modulate:a", 0.0, FADE_TIME).set_delay(0.1)
	_tween.tween_callback(Callable(self, "queue_free"))

func _process(_delta: float):
	# No longer needed, tween handles animation
	pass
