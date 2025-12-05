extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@export var speed := 120
@export var max_health := 50
var health := 0

var player_body: CharacterBody2D = null

# Distance behaviors
var stopping_distance := 130.0       # Begin circling
var circle_distance := 90.0          # Perfect orbit
var separation_distance := 70.0      # Distance to avoid other enemies

# Behavior forces
var separation_force := 250.0        # Push away from other enemies
var circle_strength := 150.0         # Strength of circling force

# Knockback
var knockback := Vector2.ZERO
var knockback_decay := 14.0


func _ready():
	health = max_health

	# Find player
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

	# --------------------------------------------------
	# 0. Knockback override
	# --------------------------------------------------
	if knockback.length() > 1:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)
		move_and_slide()
		return

	var to_player = player_body.global_position - global_position
	var distance = to_player.length()
	var move_dir := Vector2.ZERO

	# --------------------------------------------------
	# 1. FAR → Chase player
	# --------------------------------------------------
	if distance > stopping_distance:
		move_dir += to_player.normalized()

	# --------------------------------------------------
	# 2. MID RANGE → Circle player
	# --------------------------------------------------
	elif distance > circle_distance:
		var toward = to_player.normalized()
		var side = Vector2(-toward.y, toward.x)

		# Each enemy chooses clockwise or counterclockwise once
		if not has_meta("circle_dir"):
			set_meta("circle_dir", (1 if randf() > 0.5 else -1))

		var circle_dir = get_meta("circle_dir")
		move_dir += side * circle_strength * circle_dir * delta

	# --------------------------------------------------
	# 3. TOO CLOSE → Step backward
	# --------------------------------------------------
	else:
		move_dir -= to_player.normalized() * 0.4

	# --------------------------------------------------
	# 4. TRUE GROUP-BASED SEPARATION
	# --------------------------------------------------
	var separation := Vector2.ZERO

	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self:
			continue

		if not other is Node2D:
			continue

		var diff = global_position - other.global_position
		var dist = diff.length()

		if dist < separation_distance and dist > 0:
			# Weighted repel force
			separation += diff.normalized() * ((separation_distance - dist) / separation_distance)

	# Apply separation force
	move_dir += separation * separation_force * delta

	# --------------------------------------------------
	# 5. APPLY FINAL MOVEMENT
	# --------------------------------------------------
	if move_dir.length() > 0.1:
		move_dir = move_dir.normalized()
		velocity = move_dir * speed
		move_and_slide()
		set_move_anim(move_dir)
	else:
		velocity = Vector2.ZERO
		set_idle_anim(to_player.normalized())


# =====================================================
# Knockback
# =====================================================
func apply_knockback(force: Vector2):
	knockback = force


# =====================================================
# Difficulty scaling
# =====================================================
func apply_difficulty(speed_bonus: float, hp_bonus: float):
	speed += speed_bonus
	max_health += hp_bonus
	health = max_health


# =====================================================
# Animation
# =====================================================
func set_move_anim(dir: Vector2):
	var name = get_anim_name(dir, "move")
	anim.play(name)
	anim.flip_h = dir.x < 0

func set_idle_anim(dir: Vector2):
	var name = get_anim_name(dir, "idle")
	anim.play(name)
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


# =====================================================
# Death
# =====================================================
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
