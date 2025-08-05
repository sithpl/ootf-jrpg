class_name Skill extends Resource

@export var name: String = "" # Skill name
@export var description: String = "" # Short detail
@export var cost: int = 0 # AP cost
@export var effect_name: String = ""  # Matches the effect in Effects.gd
@export var effect_params: Array = [] # Extra params to pass, e.g. [amount]
@export var target_type: String = "single" # "single", "all", etc.
@export var effect_scene: String = ""            # Path to the effect scene, e.g. "res://Effects/HealEffect.tscn"
@export var effect_animation: String = ""        # Animation name to play, e.g. "heal"
@export var effect_position: String = "target"   # "caster", "target", or "screen"
@export var sfx_path: String = ""
