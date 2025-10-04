extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
var speed := 200
var last_dir := Vector2.DOWN  # Default facing down

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	# Input direction
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	# Normalize for diagonal movement
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * speed
		_play_move_animation(velocity)
		last_dir = velocity.normalized()
	else:
		_play_idle_animation(last_dir)

	move_and_slide()


# -----------------------------
# Animation Helpers
# -----------------------------
func _play_move_animation(dir: Vector2) -> void:
	if dir.y < 0:  # Up
		if dir.x != 0:
			anim.play("move_up_right")
			anim.flip_h = dir.x < 0
		else:
			anim.play("move_up")
	elif dir.y > 0:  # Down
		if dir.x != 0:
			anim.play("move_down_right")
			anim.flip_h = dir.x < 0
		else:
			anim.play("move_down")
	else: # Pure left/right
		anim.play("move_right")
		anim.flip_h = dir.x < 0


func _play_idle_animation(dir: Vector2) -> void:
	if dir.y < 0:
		if dir.x != 0:
			anim.play("idle_up_right")
			anim.flip_h = dir.x < 0
		else:
			anim.play("idle_up")
	elif dir.y > 0:
		if dir.x != 0:
			anim.play("idle_down_right")
			anim.flip_h = dir.x < 0
		else:
			anim.play("idle_down")
	else:
		anim.play("idle_left_right")
		anim.flip_h = dir.x < 0
