extends Node

var ALL_SKILLS = {}

func _ready():
	# Load all skills manually or via directory scan
	ALL_SKILLS["Heal"] = preload("res://Skills/Heal_Skill.tres")
	#ALL_SKILLS["fireball"] = preload("res://Skills/Fireball_Skill.tres")
