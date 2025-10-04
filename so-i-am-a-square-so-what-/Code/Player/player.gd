extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
var speed := 200

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO 
	if Input.is_action_pressed("ui_right"):
		velocity.x += speed
		anim.play("move_right")
		anim.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= speed
		anim.play("move_right")
		anim.flip_h=true
	else :
		anim.play("idle_left_right")
		
	move_and_slide()
	
