class_name Player extends CharacterBody2D

# Signals
signal moved(pos, run_factor)

# Onreadys
@onready var _anim_sprite : AnimatedSprite2D = $AnimatedSprite2D
var movement_locked: bool = false

# Constants
const SPEED : int = 110
const IDLE_FRAME : int = 0

func _ready():
	Globals.player = self
	_anim_sprite.set_animation("DOWN")
	idle()

func _process(_delta: float):
	if Globals.player.movement_locked:
		return
		print("Movement locked")
		
	var movement : Vector2 = Math.get_four_direction_vector(false)
	if movement.is_equal_approx(Vector2.ZERO):
		idle()
		return
	
	if !_anim_sprite.is_playing:
		_anim_sprite.set_frame(0)
	
	var run_factor : float = 1.75 if Input.is_action_pressed("ui_cancel") else 1.0
	_anim_sprite.speed_scale = run_factor
	_anim_sprite.play(Math.convert_vec2_to_facing_string(movement))
	velocity = movement * SPEED * run_factor
	move_and_slide()
	emit_signal("moved", position, run_factor)
	
func idle():
	_anim_sprite.set_frame(IDLE_FRAME)
	_anim_sprite.stop()
	pass

func enable(on: bool):
	set_process(on)
	if !on:
		idle()
