extends ProgressBar
#class_name ATBBar 
#
#signal filled()
#
#const SPEED_BASE: float = 0.10
#
#@onready var _anim: AnimationPlayer = $AnimationPlayer
#
#func _ready():
	#_anim.play("RESET")
	#value = randf_range(min_value, max_value * 0.75)
#
#func reset():
	#modulate = Color.WHITE
	#value = min_value
	#set_process(true)
#
#func stop():
	#set_process(false)
#
#func _process(_delta: float):
	#value += SPEED_BASE
	#
	#if is_equal_approx(value, max_value):
		##_anim.play("highlight")
		#modulate = Color("fdc02f")
		#stop()
		#filled.emit()
		## TODO begin animation
