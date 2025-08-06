extends Node

var effects = {}

func _ready():
	effects = {
		"heal": Callable(self, "effect_heal"),
		"damage": Callable(self, "effect_damage"),
		"restore_ap": Callable(self, "effect_restore_ap"),
		"cure_poison": Callable(self, "effect_cure_poison"),
		"revive": Callable(self, "effect_revive"),
	}

func apply_effect(effect_name: String, target, params=[]):
	if effect_name in effects:
		return effects[effect_name].callv([target] + params)
	else:
		print("Effect not found: ", effect_name)
		return null

# effect_heal: Heal target HP
func effect_heal(target, amount):
	if target and target.has_method("heal"):
		return target.heal(amount)
	return null

# effect_damage: Deal damage to target HP
func effect_damage(target, amount):
	print("Effects.gd: effect_damage called with target: %s amount: %d" % [target.name, amount])
	if target and target.has_method("heal"):
		return target.heal(-abs(amount))
	return null

# effect_restore_ap: Restore target AP
func effect_restore_ap(target, amount):
	if target and target.has_method("restore_ap"):
		return target.restore_ap(amount) 
	return null

# effect_cure_poison: Cure Poison status
func effect_cure_poison(target):
	if target and target.has_method("cure_poison"):
		return target.cure_poison() 
	return null

# effect_revive: Revive target with 50% HP
func effect_revive(target, percent=0.5):
	if target and target.has_method("revive"):
		return target.revive(percent) 
	return null
