class_name QTEPrompt extends Control

signal qte_result(success: bool)

@export var window_time: float = 1.0
@onready var _timer: Timer = $Timer

func _ready():
	visible = false
	_timer.one_shot = true
	_timer.autostart = false
	#_timer.disconnect("timeout", self, "_on_timeout") if _timer.is_connected("timeout", self, "_on_timeout")
	#_timer.connect("timeout", Callable(self), "_on_timeout")

func show_qte(duration: float = 0.0) -> void:
	# choose either the passed-in duration or the default
	var t = duration if duration > 0.0 else window_time

	visible = true
	_timer.start(t)   # start(duration) will set wait_time = duration

func _on_timeout() -> void:
	visible = false
	emit_signal("qte_result", false)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_timer.stop()
		visible = false
		emit_signal("qte_result", true)
