extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@export var speed := 120
@export var max_health := 50
var health := 0

var player_body: CharacterBody2D = null

# Movement pause when close to player
var is_moving := true
var pause_timer := 0.0
var pause_duration := 0.4

# Knockback system
var knockback := Vector2.ZERO
var knockback_decay := 14.0


func _ready():
	# Health must be set AFTER spawner difficulty scaling
	health = max_health

	# Locate player
	var root = get_tree().root.find_child("player", true, false)
	if root:
		for c in root.get_children():
			if c is CharacterBody2D:
				player_body = c
				break

	set_idle_anim(Vector2.DOWN)


func _physics_process(delta):
	if not player_body:
		return

	# Apply knockback first
	if knockback.length() > 1:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)
		move_and_slide()
		return

	# Pause behavior
	if not is_moving:
		pause_timer -= delta
		if pause_timer <= 0:
			is_moving = true
		return

	var direction = (player_body.global_position - global_position).normalized()
	var distance = global_position.distance_to(player_body.global_position)
	var stopping_distance := 20.0

	if distance <= stopping_distance:
		velocity = Vector2.ZERO
		is_moving = false
		pause_timer = pause_duration
		set_idle_anim(direction)
		return

	# Chase player
	velocity = direction * speed
	move_and_slide()

	if velocity.length() > 0.1:
		set_move_anim(direction)
	else:
		set_idle_anim(direction)


# Knockback (called by bullet)
func apply_knockback(force: Vector2):
	knockback = force


# ==========================================================
#   UNIVERSAL DIFFICULTY SCALING FUNCTION (Spawner uses this)
# ==========================================================
func apply_difficulty(speed_bonus: float, hp_bonus: float):
	speed += speed_bonus
	max_health += hp_bonus
	health = max_health


# ==========================================================
#   Animation helpers
# ==========================================================
func set_move_anim(dir: Vector2):
	var name = get_anim_name(dir, "move")
	anim.play(name)
	apply_flip(dir)

func set_idle_anim(dir: Vector2):
	var name = get_anim_name(dir, "idle")
	anim.play(name)
	apply_flip(dir)

func apply_flip(dir: Vector2):
	anim.flip_h = dir.x < 0

func get_anim_name(dir: Vector2, action: String) -> String:
	if abs(dir.x) > 0.5 and abs(dir.y) < 0.5:
		return "%s_left_right" % action
	elif abs(dir.x) < 0.5 and dir.y < -0.5:
		return "%s_up" % action
	elif abs(dir.x) < 0.5 and dir.y > 0.5:
		return "%s_down" % action
	elif dir.y < 0:
		return "%s_up_right" % action
	else:
		return "%s_down_right" % action


# ==========================================================
#   Damage and Death
# ==========================================================
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	set_physics_process(false)
	set_process(false)
	velocity = Vector2.ZERO

	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	anim.play("death")
	await get_tree().create_timer(0.9).timeout
	queue_free()
