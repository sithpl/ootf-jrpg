class_name Town_Discord extends Node2D

signal tile_transition_entered(destination)

@onready var npc_scene = preload("res://Scenes/NPC.tscn")
@onready var _player: Player = $Player
@onready var _transition_area: TransitionArea = $TransitionArea
@onready var area_name : String = "Discord"

# List of NPCs for this town
var npc_data = [
	{
		"npc_id": "kanili",
		"position": Vector2(-227, 318)
	},
	{
		"npc_id": "cracker",
		"position": Vector2(-103, 318)
		# No spawn_direction; will use default
	},
	{
		"npc_id": "shadow",
		"position": Vector2(-265, 318)
	},
	{
		"npc_id": "drak",
		"position": Vector2(-696, 64)
	},
	{
		"npc_id": "friz",
		"position": Vector2(-636, 64)
	},
	{
		"npc_id": "erik",
		"position": Vector2(-576, 64)
	},
	{
		"npc_id": "dan",
		"position": Vector2(-516, 64)
	},
]

func _ready():
	town_entrance()
	_transition_area.destination = "Overworld"
	if _transition_area:
		_transition_area.connect("area_exited", func(body):
			on_transition_area_body_exited(body, _transition_area.destination)
		)
	if area_name != null:
		TextUi.show_area_name(area_name)
	# Spawn town NPCs
	for data in npc_data:
		var npc = npc_scene.instantiate()
		npc.npc_id = data["npc_id"]
		#npc.recruitable = data["recruitable"]
		if npc.should_spawn():
			npc.position = data["position"]
			add_child(npc)
		else:
			npc.queue_free()
	
func on_transition_area_body_exited(body: Node, destination: String):
	Globals.last_exit = "Town_Discord_SouthGate"
	if body is Player:
		emit_signal("tile_transition_entered", destination)
		print("tile_transition_entered emitted! -> " + destination)
	
func town_entrance():
	self.modulate = Color(0, 0, 0, 1)
	_player.get_node("AnimatedSprite2D").play("UP")
	TextUi.show_area_name(area_name)
	MusicManager.play_type_theme(MusicManager.ThemeType.TOWN)
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
