extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var speed := 500
@export var max_health := 50
var health := max_health

# For direction testing
var directions := [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(1, -1),   # up-right
	Vector2(-1, -1),  # up-left
	Vector2(1, 1),    # down-right
	Vector2(-1, 1)    # down-left
]
var current_dir_index := 0
var time_accum := 0.0
var switch_time := 1.5
var moving := true

func _ready():
	add_to_group("enemy")
	set_idle_anim(Vector2.DOWN)

func _physics_process(delta):
	time_accum += delta

	if time_accum > switch_time:
		time_accum = 0.0
		moving = !moving
		if not moving:
			set_idle_anim(directions[current_dir_index])
		else:
			current_dir_index = (current_dir_index + 1) % directions.size()
			set_move_anim(directions[current_dir_index])

	if moving:
		velocity = directions[current_dir_index].normalized() * speed * delta * 10
		move_and_slide()
	else:
		velocity = Vector2.ZERO

# ======================
# Animation helpers
# ======================
func set_move_anim(dir: Vector2):
	var name := get_anim_name(dir, "move")
	anim.play(name)

func set_idle_anim(dir: Vector2):
	var name := get_anim_name(dir, "idle")
	anim.play(name)

func get_anim_name(dir: Vector2, action: String) -> String:
	if dir.x > 0.5 and abs(dir.y) < 0.5:
		return "%s_left_right" % action
	elif dir.x < -0.5 and abs(dir.y) < 0.5:
		return "%s_left_right" % action
	elif dir.y < -0.5 and abs(dir.x) < 0.5:
		return "%s_up" % action
	elif dir.y > 0.5 and abs(dir.x) < 0.5:
		return "%s_down" % action
	elif dir.x > 0 and dir.y < 0:
		return "%s_up_right" % action
	elif dir.x < 0 and dir.y < 0:
		return "%s_up_left" % action
	elif dir.x > 0 and dir.y > 0:
		return "%s_down_right" % action
	elif dir.x < 0 and dir.y > 0:
		return "%s_down_left" % action
	else:
		return "%s_down" % action

# ======================
# Damage system
# ======================
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

# ======================
# Death with 2-second delay
# ======================
func die():
	set_physics_process(false)
	set_process(false)
	velocity = Vector2.ZERO

	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	anim.play("death")

	await get_tree().create_timer(1.0).timeout  # wait for 1 seconds
	queue_free()
