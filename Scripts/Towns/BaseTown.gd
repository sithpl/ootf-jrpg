class_name BaseTown extends Node2D

# Signals for entering/exiting the town, or triggering town-specific events
signal town_entered
signal town_exited

# Common properties for all towns
var town_name: String
var npc_list: Array = []
var shop_inventory: Array = []
var background_music: String = ""
var description: String = ""

func _ready():
	$AnimationPlayer.play("fade_in")  # Play fade_in animation
	await $AnimationPlayer.animation_finished
	# Called when the node is added to the scene tree.
	#emit_signal("town_entered")
	#_on_ready_town()

func _on_ready_town():
	# To be overridden by child scenes for specific setup
	pass

func leave_town():
	emit_signal("town_exited")
	queue_free()

func get_npc_names() -> Array:
	return npc_list

func get_shop_inventory() -> Array:
	return shop_inventory

func get_background_music() -> String:
	return background_music

func get_description() -> String:
	return description
