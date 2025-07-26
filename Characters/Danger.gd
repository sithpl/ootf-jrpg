class_name Danger extends Node

# Signals
signal limit_reached()

# Exports
@export var limit_base : int = 400
@export var enabled : bool = true
@export var show_debug_text : bool = true

# Onreadys
@onready var _canvas_layer : CanvasLayer = $CanvasLayer
@onready var _debug_label : Label = $CanvasLayer/MarginContainer/Limit

# Variables
var limit : int = 0

func _ready():
	#DEBUG print("Danger.gd/_ready() called")
	set_limit()
	
	if show_debug_text:
		_canvas_layer.show()
	else:
		_canvas_layer.queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed:
		match event.keycode:
			KEY_P:
				enabled = !enabled
			KEY_O:
				_canvas_layer.visible = !_canvas_layer.visible

func set_limit():
	#DEBUG print("Danger.gd/set_limit() called")
	var spread : float = 0.5
	limit = randf_range(limit_base * spread, limit_base * (1 + spread))
	_debug_label.text = str(limit)

func countdown(amount: int = 1):
	#DEBUG print("Danger.gd/countdown() called")
	if enabled:
		limit -= amount
	
	if limit <= 0:
		emit_signal("limit_reached")
		#DEBUG print("signal -> limit_reached emitted!")
		set_limit()
	
	if show_debug_text:
		_debug_label.text = str(limit)
