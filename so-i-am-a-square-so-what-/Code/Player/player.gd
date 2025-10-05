extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var gun_scene: PackedScene

var speed := 200
var last_move_dir := Vector2.DOWN
var gun_instance: Node2D

@onready var marker_up: Node2D = $up
@onready var marker_down: Node2D = $down
@onready var marker_left: Node2D = $left
@onready var marker_right: Node2D = $right

func _ready():
	if gun_scene:
		gun_instance = gun_scene.instantiate() as Node2D
		add_child(gun_instance)

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO

	# Movement input
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * speed
		_play_move_animation(velocity)
		last_move_dir = velocity.normalized()
	else:
		_play_idle_animation(last_move_dir)

	move_and_slide()
	
	# Always use mouse for aiming
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	_update_gun_position(mouse_dir)

	# Shooting
	if Input.is_action_just_pressed("shoot"):
		if gun_instance and gun_instance.has_method("shoot"):
			gun_instance.shoot(mouse_dir)

# -----------------------------
# Gun Positioning & Rotation
# -----------------------------
func _update_gun_position(dir: Vector2):
	if not gun_instance:
		return
	
	# Use a threshold to determine directions (including diagonals)
	var threshold = 0.5
	
	# Check for cardinal directions first
	if abs(dir.x) < threshold and dir.y < -threshold:  # Up
		gun_instance.position = marker_up.position
	elif abs(dir.x) < threshold and dir.y > threshold:  # Down
		gun_instance.position = marker_down.position
	elif dir.x < -threshold and abs(dir.y) < threshold:  # Left
		gun_instance.position = marker_left.position
	elif dir.x > threshold and abs(dir.y) < threshold:  # Right
		gun_instance.position = marker_right.position
	# Now handle diagonals
	elif dir.x < -threshold and dir.y < -threshold:  # Up-left
		gun_instance.position = marker_left.position
	elif dir.x > threshold and dir.y < -threshold:  # Up-right
		gun_instance.position = marker_up.position
	elif dir.x < -threshold and dir.y > threshold:  # Down-left
		gun_instance.position = marker_down.position
	elif dir.x > threshold and dir.y > threshold:  # Down-right
		gun_instance.position = marker_right.position

	# Rotate gun based on direction
	gun_instance.rotation = dir.angle()

# -----------------------------
# Animation Helpers
# -----------------------------
func _play_move_animation(dir: Vector2) -> void:
	# Use a threshold to determine which animation to play
	var threshold = 0.5
	
	# Check for cardinal directions first
	if abs(dir.x) < threshold and dir.y < -threshold:  # Up
		anim.play("move_up")
		anim.flip_h = false
	elif abs(dir.x) < threshold and dir.y > threshold:  # Down
		anim.play("move_down")
		anim.flip_h = false
	elif dir.x < -threshold and abs(dir.y) < threshold:  # Left
		anim.play("move_right")
		anim.flip_h = true
	elif dir.x > threshold and abs(dir.y) < threshold:  # Right
		anim.play("move_right")
		anim.flip_h = false
	# Now handle diagonals
	elif dir.x < -threshold and dir.y < -threshold:  # Up-left
		anim.play("move_right")
		anim.flip_h = true
	elif dir.x > threshold and dir.y < -threshold:  # Up-right
		anim.play("move_right")
		anim.flip_h = false
	elif dir.x < -threshold and dir.y > threshold:  # Down-left
		anim.play("move_right")
		anim.flip_h = true
	elif dir.x > threshold and dir.y > threshold:  # Down-right
		anim.play("move_right")
		anim.flip_h = false

func _play_idle_animation(dir: Vector2) -> void:
	# Use the same logic as move animation but with idle animations
	var threshold = 0.5
	
	# Check for cardinal directions first
	if abs(dir.x) < threshold and dir.y < -threshold:  # Up
		anim.play("idle_up")
		anim.flip_h = false
	elif abs(dir.x) < threshold and dir.y > threshold:  # Down
		anim.play("idle_down")
		anim.flip_h = false
	elif dir.x < -threshold and abs(dir.y) < threshold:  # Left
		anim.play("idle_left_right")
		anim.flip_h = true
	elif dir.x > threshold and abs(dir.y) < threshold:  # Right
		anim.play("idle_left_right")
		anim.flip_h = false
	# Now handle diagonals
	elif dir.x < -threshold and dir.y < -threshold:  # Up-left
		anim.play("idle_left_right")
		anim.flip_h = true
	elif dir.x > threshold and dir.y < -threshold:  # Up-right
		anim.play("idle_left_right")
		anim.flip_h = false
	elif dir.x < -threshold and dir.y > threshold:  # Down-left
		anim.play("idle_left_right")
		anim.flip_h = true
	elif dir.x > threshold and dir.y > threshold:  # Down-right
		anim.play("idle_left_right")
		anim.flip_h = false
