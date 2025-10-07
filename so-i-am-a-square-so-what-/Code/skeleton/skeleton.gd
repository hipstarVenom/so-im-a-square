extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var speed := 500
@export var max_health := 50
var health := max_health

# Directions for 8-way movement
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

	# Switch direction or idle
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
	apply_flip(dir)

func set_idle_anim(dir: Vector2):
	var name := get_anim_name(dir, "idle")
	anim.play(name)
	apply_flip(dir)

# Apply horizontal flip for animations that can face left
func apply_flip(dir: Vector2):
	var flip_needed := false
	if anim.animation.ends_with("_left_right") or anim.animation.ends_with("_up_right") or anim.animation.ends_with("_down_right"):
		flip_needed = dir.x < 0
	anim.flip_h = flip_needed

# Determine animation name
func get_anim_name(dir: Vector2, action: String) -> String:
	if abs(dir.x) > 0.5 and abs(dir.y) < 0.5:
		return "%s_left_right" % action
	elif abs(dir.x) < 0.5 and dir.y < -0.5:
		return "%s_up" % action
	elif abs(dir.x) < 0.5 and dir.y > 0.5:
		return "%s_down" % action
	elif dir.x > 0 and dir.y < 0:
		return "%s_up_right" % action
	elif dir.x < 0 and dir.y < 0:
		return "%s_up_right" % action
	elif dir.x > 0 and dir.y > 0:
		return "%s_down_right" % action
	elif dir.x < 0 and dir.y > 0:
		return "%s_down_right" % action
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
	await get_tree().create_timer(2.0).timeout  # wait for 2 seconds
	queue_free()
