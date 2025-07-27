extends Node

var total_seconds: float = 0

func _process(delta):
	total_seconds += delta

func get_time_string() -> String:
	var seconds = int(total_seconds) % 60
	var minutes = int(total_seconds / 60) % 60
	var hours = int(total_seconds / 3600)
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
