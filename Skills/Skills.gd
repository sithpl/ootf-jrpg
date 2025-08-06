extends Node

var ALL_SKILLS = {}

func _ready():
	# Load all skills manually or via directory scan
	ALL_SKILLS["Heal"] = preload("res://Skills/Heal_Skill.tres")
	ALL_SKILLS["Fireblast"] = preload("res://Skills/Fireblast_Skill.tres")
	ALL_SKILLS["Volley"] = preload("res://Skills/Volley_Skill.tres")
