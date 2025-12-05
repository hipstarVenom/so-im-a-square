extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var gun_scene: PackedScene

# Movement
var speed := 320
var last_move_dir := Vector2.DOWN

# Gun
var gun_instance: Node2D
@onready var marker_up: Node2D = $up
@onready var marker_down: Node2D = $down
@onready var marker_left: Node2D = $left
@onready var marker_right: Node2D = $right

# Shooting
var can_shoot := true
var shoot_cooldown := 0.10


func _ready():
	if gun_scene:
		gun_instance = gun_scene.instantiate()
		add_child(gun_instance)


func _physics_process(delta: float) -> void:
	_process_movement()
	_process_aiming()
	_process_shooting()


# ---------------------------------------------------------
# MOVEMENT
# ---------------------------------------------------------
func _process_movement():
	velocity = Vector2.ZERO

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
		last_move_dir = velocity.normalized()
		_play_move_animation(last_move_dir)
	else:
		_play_idle_animation(last_move_dir)

	move_and_slide()


# ---------------------------------------------------------
# AIMING
# ---------------------------------------------------------
func _process_aiming():
	if not gun_instance:
		return

	var dir := (get_global_mouse_position() - global_position).normalized()

	# pick horizontal/vertical marker
	if abs(dir.x) > abs(dir.y):
		gun_instance.position = marker_right.position if dir.x > 0 else marker_left.position
	else:
		gun_instance.position = marker_down.position if dir.y > 0 else marker_up.position

	gun_instance.rotation = dir.angle()


# ---------------------------------------------------------
# SHOOTING
# ---------------------------------------------------------
func _process_shooting():
	if can_shoot and Input.is_action_pressed("shoot") and gun_instance:
		var mouse_dir := (get_global_mouse_position() - global_position).normalized()
		gun_instance.shoot(mouse_dir)
		_start_shoot_cooldown()


func _start_shoot_cooldown():
	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


# ---------------------------------------------------------
# ANIMATIONS (optimized)
# ---------------------------------------------------------
func _play_move_animation(dir: Vector2):
	anim.flip_h = dir.x < 0
	var t := 0.5

	if abs(dir.x) < t and dir.y < -t:
		anim.play("move_up")
	elif abs(dir.x) < t and dir.y > t:
		anim.play("move_down")
	elif dir.x > t and abs(dir.y) < t:
		anim.play("move_right")
	elif dir.x < -t and abs(dir.y) < t:
		anim.play("move_right")  # flip makes it left
	elif dir.x > t and dir.y < -t:
		anim.play("move_up_right")
	elif dir.x < -t and dir.y < -t:
		anim.play("move_up_right")
	elif dir.x > t and dir.y > t:
		anim.play("move_down_right")
	elif dir.x < -t and dir.y > t:
		anim.play("move_down_right")


func _play_idle_animation(dir: Vector2):
	anim.flip_h = dir.x < 0
	var t := 0.5

	if abs(dir.x) < t and dir.y < -t:
		anim.play("idle_up")
	elif abs(dir.x) < t and dir.y > t:
		anim.play("idle_down")
	elif dir.x > t and abs(dir.y) < t:
		anim.play("idle_left_right")
	elif dir.x < -t and abs(dir.y) < t:
		anim.play("idle_left_right")
	elif dir.x > t and dir.y < -t:
		anim.play("idle_up_right")
	elif dir.x < -t and dir.y < -t:
		anim.play("idle_up_right")
	elif dir.x > t and dir.y > t:
		anim.play("idle_down_right")
	elif dir.x < -t and dir.y > t:
		anim.play("idle_down_right")
