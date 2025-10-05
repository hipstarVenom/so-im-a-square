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
@onready var marker_center: Node2D = $center  # optional for centering

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
	var threshold = 0.1

	# Decide gun position (marker) based on dominant axis
	if abs(dir.x) < threshold and dir.y < -threshold:
		gun_instance.position = marker_up.position
	elif abs(dir.x) < threshold and dir.y > threshold:
		gun_instance.position = marker_down.position
	elif dir.x < -threshold and abs(dir.y) < threshold:
		gun_instance.position = marker_left.position
	elif dir.x > threshold and abs(dir.y) < threshold:
		gun_instance.position = marker_right.position
	else:  # diagonal
		if dir.y < 0:
			gun_instance.position = marker_up.position
		else:
			gun_instance.position = marker_down.position

	# Rotate gun naturally based on movement direction
	if dir.length() > threshold:
		gun_instance.rotation = dir.angle()  # radians, clockwise from +X


# -----------------------------
# Animation Helpers
# -----------------------------
func _play_move_animation(dir: Vector2) -> void:
	if dir.y < 0:
		if dir.x != 0:
			anim.play("move_up_right")
		else:
			anim.play("move_up")
	elif dir.y > 0:
		if dir.x != 0:
			anim.play("move_down_right")
		else:
			anim.play("move_down")
	else:
		anim.play("move_right")

func _play_idle_animation(dir: Vector2) -> void:
	if dir.y < 0:
		if dir.x != 0:
			anim.play("idle_up_right")
		else:
			anim.play("idle_up")
	elif dir.y > 0:
		if dir.x != 0:
			anim.play("idle_down_right")
		else:
			anim.play("idle_down")
	else:
		anim.play("idle_left_right")
