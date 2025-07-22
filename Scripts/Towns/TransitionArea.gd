class_name TransitionArea extends Area2D

@export var destination: String = ""

func _ready():
	self.connect("area_exited", Callable(self, "_on_area_exited"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_exited(body):
	print("TransitionArea: emitting area_exited for", body)
	emit_signal("area_exited", body)
