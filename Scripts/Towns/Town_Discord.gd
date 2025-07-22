class_name Town_Discord extends Node2D

signal tile_transition_entered(destination)

# Onreadys
@onready var _player              :Player            = $Player
@onready var _transition_area : TransitionArea = $TransitionArea

func _ready():
	town_entrance()
	_transition_area.destination = "Overworld"
	if _transition_area:
		_transition_area.connect("area_exited", func(body):
			#DEBUG print("Lambda for area_exited called with body:", body)
			on_transition_area_body_exited(body, _transition_area.destination)
)
		#DEBUG print("Connected: area_exited signal to on_transition_area_body_exited")

func on_transition_area_body_exited(body: Node, destination: String):
	#DEBUG print("Handler called! body:", body, "destination:", destination)
	Globals.last_exit = "Town_Discord_SouthGate"
	if body is Player:
		emit_signal("tile_transition_entered", destination)
		print("tile_transition_entered emitted! -> " + destination)
	
func town_entrance():
	self.modulate = Color(0, 0, 0, 1) # Start fully black
	_player.get_node("AnimatedSprite2D").play("UP")
	MusicManager.play_type_theme(MusicManager.ThemeType.TOWN)
	$AnimationPlayer.play("fade_in")  # Play fade_in animation
	await $AnimationPlayer.animation_finished
	
	
