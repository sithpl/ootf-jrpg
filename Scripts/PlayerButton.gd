class_name PlayerButton extends BattleActorButton

func _ready():
	set_data(Data.party[get_index()])

func _on_data_is_defeated():
		self_modulate = Color.BLACK # TODO Replace temporary solution here
