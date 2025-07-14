class_name MenuCursor extends TextureRect

const OFFSET: Vector2 = Vector2(-18, -2)

var target: Node = null

func _ready():
	get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)
	set_process(false)
	hide()

func _process(_delta: float):
	global_position = target.global_position + OFFSET
	#visible = target.visible

func _on_viewport_gui_focus_changed(node: Control):
	if node is BaseButton:
		if target:
			target.tree_exiting.disconnect(_on_target_tree_exiting)

		target = node
		target.tree_exiting.connect(_on_target_tree_exiting.bind(target))
		show()
		set_process(true)
	else:
		hide()
		set_process(false)

func _on_target_tree_exiting(node: Control):
	if node == target:
		target = null
		set_process(false)
