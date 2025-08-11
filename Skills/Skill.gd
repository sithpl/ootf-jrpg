class_name Skill extends Resource

@export var name                 :String     = ""             # Skill name
@export var description          :String     = ""             # Short detail
@export var cost                 :int        = 0              # AP cost
@export var effect_name          :String     = ""             # Matches the effect in Effects.gd
@export var effect_params        :Array      = []             # Extra params to pass (damage/heal amount)
@export var target_type          :String     = "single"       # "single", "all", etc.
@export var effect_scene         :String     = ""             # Path to the effect scene
@export var base_animation       :String     = ""             # Animation played during travel or on cast
@export var impact_animation     :String     = ""             # Animation played on arrival/impact
@export var effect_position      :String     = "target"       # "caster", "target", or "screen"
@export var sfx_cast_delay       :float      = 0.0            # Time sfx with animation frame
@export var sfx_charge_path      :String     = ""             # Path to charge sound
@export var sfx_cast_path        :String     = ""             # Path to cast sound
@export var sfx_impact_path      :String     = ""             # Path to impact/hit sound
@export var effect_offset        :Vector2    = Vector2.ZERO   # X/Y offset if needed
