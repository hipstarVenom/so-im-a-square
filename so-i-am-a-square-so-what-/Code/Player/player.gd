extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var gun_scene: PackedScene

var speed := 200
var last_dir := Vector2.DOWN
var gun_instance: Node2D

@onready var marker_up: Node2D = $up
@onready var marker_down: Node2D = $down
@onready var marker_left: Node2D = $left
@onready var marker_right: Node2D = $right

func _ready():
	if gun_scene:
		gun_instance = gun_scene.instantiate() as Node2D
		add_child(gun_instance)
		_update_gun_position()

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
		last_dir = velocity.normalized()
	else:
		_play_idle_animation(last_dir)

	move_and_slide()
	_update_gun_position()

	# Shooting
	if Input.is_action_just_pressed("shoot"):
		if gun_instance and gun_instance.has_method("shoot"):
			gun_instance.shoot(last_dir)

# -----------------------------
# Gun Positioning & Rotation
# -----------------------------
func _update_gun_position():
	if not gun_instance:
		return

	var dir = last_dir
	
	# Use a threshold to determine cardinal directions
	var threshold = 0.5  # Increased threshold for better diagonal detection
	
	# Check for cardinal directions first with higher threshold
	if abs(dir.x) < threshold and dir.y < -threshold:  # Up
		gun_instance.position = marker_up.position
	elif abs(dir.x) < threshold and dir.y > threshold:  # Down
		gun_instance.position = marker_down.position
	elif dir.x < -threshold and abs(dir.y) < threshold:  # Left
		gun_instance.position = marker_left.position
	elif dir.x > threshold and abs(dir.y) < threshold:  # Right
		gun_instance.position = marker_right.position
	else:
		# For diagonals, use the direction with the larger absolute value
		if abs(dir.x) > abs(dir.y):
			if dir.x < 0:  # Left-dominant diagonal
				gun_instance.position = marker_left.position
			else:  # Right-dominant diagonal
				gun_instance.position = marker_right.position
		else:
			if dir.y < 0:  # Up-dominant diagonal
				gun_instance.position = marker_up.position
			else:  # Down-dominant diagonal
				gun_instance.position = marker_down.position

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
	else:
		# Handle diagonals
		if dir.y < 0:  # Up diagonals
			anim.play("move_up_right")
			anim.flip_h = dir.x < 0
		else:  # Down diagonals
			anim.play("move_down_right")
			anim.flip_h = dir.x < 0

func _play_idle_animation(dir: Vector2) -> void:
	# Use the same logic as move animation but with idle animations
	var threshold = 0.5
	
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
	else:
		# Handle diagonals
		if dir.y < 0:  # Up diagonals
			anim.play("idle_up_right")
			anim.flip_h = dir.x < 0
		else:  # Down diagonals
			anim.play("idle_down_right")
			anim.flip_h = dir.x < 0
