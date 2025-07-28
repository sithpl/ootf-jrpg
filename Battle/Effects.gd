extends Node

var effects = {}

func _ready():
	effects = {
		"heal": Callable(self, "effect_heal"),
		"restore_ap": Callable(self, "effect_restore_ap"),
		"cure_poison": Callable(self, "effect_cure_poison"),
		"revive": Callable(self, "effect_revive"),
	}

func apply_effect(effect_name: String, target, params=[]):
	if effect_name in effects:
		effects[effect_name].callv([target] + params)
	else:
		print("Effect not found: ", effect_name)

# effect_heal: Heal target HP
func effect_heal(target, amount):
	if target and target.has_method("heal"):
		target.heal(amount)

# effect_restore_ap: Restore target AP
func effect_restore_ap(target, amount):
	if target and target.has_method("restore_ap"):
		target.restore_ap(amount)

# effect_cure_poison: Cure Poison status
func effect_cure_poison(target):
	if target and target.has_method("cure_poison"):
		target.cure_poison()

# effect_revive: Revive target with 50% HP
func effect_revive(target, percent=0.5):
	if target and target.has_method("revive"):
		target.revive(percent)
