extends Node

var ALL_SKILLS = {}

func _ready():
	# Load all skills manually or via directory scan
	ALL_SKILLS["Heal"] = preload("res://Skills/Heal_Skill.tres") # Priest
	ALL_SKILLS["Fireblast"] = preload("res://Skills/Fireblast_Skill.tres") # Mage
	ALL_SKILLS["Volley"] = preload("res://Skills/Volley_Skill.tres") # Ranger
	ALL_SKILLS["Smite"] = preload("res://Skills/Smite_Skill.tres") # Paladin
	ALL_SKILLS["Charge"] = preload("res://Skills/Charge_Skill.tres") # Lancer
	ALL_SKILLS["P.Arrow"] = preload("res://Skills/PoisonArrow_Skill.tres") # Archer
