extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
var speed := 200
var last_facing := "down"  

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = speed
		anim.play("move_right")
		anim.flip_h = false
		last_facing = "right"
		
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -speed
		anim.play("move_right") 
		anim.flip_h = true
		last_facing = "left"
		
	elif Input.is_action_pressed("ui_down"):
		velocity.y = speed
		anim.play("move_down")
		last_facing = "down"
		
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -speed
		anim.play("move_up")
		last_facing = "up"
		
	else:
		match last_facing:
			"right", "left":
				anim.play("idle_left_right")
				anim.flip_h = (last_facing == "left")
			"down":
				anim.play("idle_down")
			"up":
				anim.play("idle_up")

	move_and_slide()
