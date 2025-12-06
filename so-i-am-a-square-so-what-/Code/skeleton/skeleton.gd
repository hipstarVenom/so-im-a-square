extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var bullet_scene: PackedScene
@export var shoot_interval := 1.2

@export var speed := 120
@export var max_health := 40
var health := 0

var player_body: CharacterBody2D = null

# Distance control
var ideal_min := 120.0
var ideal_max := 160.0
var shoot_range := 260.0

# Strafing
var strafe_strength := 0.8

# Enemy spacing
var separation_distance := 80.0
var separation_force := 200.0

# Bounce
var bounce_dir := Vector2.ZERO
var bounce_time := 0.0
var bounce_duration := 0.20

# Shooting
var shoot_timer := 0.0

# Knockback
var knockback := Vector2.ZERO
var knockback_decay := 14.0


func _ready():
	health = max_health

	# ----------------------------------------------------
	# FIND PLAYER
	# ----------------------------------------------------
	var root = get_tree().root.find_child("player", true, true)
	if root:
		player_body = root

	# ----------------------------------------------------
	# FORCE SKELETON TO APPEAR NEAR PLAYER (IMPORTANT!)
	# ----------------------------------------------------
	ensure_visible_spawn()

	set_idle_anim(Vector2.DOWN)



# ========================================================
# FORCE ENEMY TO SPAWN AROUND PLAYER (VISIBLE ALWAYS)
# ========================================================
func ensure_visible_spawn():
	if player_body == null:
		return

	# enemy spawns 140px around player (on-screen)
	var angle = randf() * TAU
	var radius = 140.0

	global_position = player_body.global_position +Vector2(cos(angle), sin(angle)) * radius




# ========================================================
# MAIN LOOP
# ========================================================
func _physics_process(delta):
	if not player_body:
		return

	# Knockback override
	if knockback.length() > 1:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)
		move_and_slide()
		return

	# Bounce override
	if bounce_time > 0:
		bounce_time -= delta
		velocity = bounce_dir * speed
		move_and_slide()
		return

	var to_player = player_body.global_position - global_position
	var dist = to_player.length()
	var move_dir := Vector2.ZERO
	var toward = to_player.normalized()

	# ====================================================
	# SHOOT AT VISIBLE RANGE (0–260px)
	# ====================================================
	if dist <= shoot_range:
		_process_shooting(delta, toward)

	# ====================================================
	# DISTANCE CONTROL
	# ====================================================

	if dist < ideal_min:
		# too close → back away
		move_dir -= toward

	elif dist > ideal_max:
		# too far → approach
		move_dir += toward

	else:
		# in good range → strafe
		var side = Vector2(-toward.y, toward.x)
		move_dir += side * strafe_strength


	# ====================================================
	# SEPARATION (avoid clustering)
	# ====================================================
	var repel := Vector2.ZERO

	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self:
			continue

		if not e is Node2D:
			continue

		var diff = global_position - e.global_position
		var d = diff.length()

		if d < separation_distance and d > 0:
			repel += diff.normalized() * ((separation_distance - d) / separation_distance)

	move_dir += repel * separation_force * delta


	# ====================================================
	# MOVEMENT & ANIMATION
	# ====================================================
	if move_dir.length() > 0.1:
		move_dir = move_dir.normalized()
		velocity = move_dir * speed

		var col = move_and_collide(velocity * delta)
		if col and col.get_collider().is_in_group("enemy"):
			_start_bounce()

		set_move_anim(move_dir)

	else:
		velocity = Vector2.ZERO
		set_idle_anim(toward)



# ========================================================
# SHOOTING (STRAIGHT LINE — NO HOMING)
# ========================================================
func _process_shooting(delta, dir):
	shoot_timer -= delta
	if shoot_timer > 0:
		return

	shoot_timer = shoot_interval

	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = global_position
	bullet.set_direction(dir)
	bullet.rotation = dir.angle()



# ========================================================
# BOUNCE
# ========================================================
func _start_bounce():
	bounce_dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	bounce_time = bounce_duration



# ========================================================
# Knockback
# ========================================================
func apply_knockback(force: Vector2):
	knockback = force



# ========================================================
# Difficulty scaling
# ========================================================
func apply_difficulty(speed_bonus: float, hp_bonus: float):
	speed += speed_bonus
	max_health += hp_bonus
	health = max_health



# ========================================================
# Animation
# ========================================================
func set_move_anim(dir: Vector2):
	anim.play(get_anim_name(dir, "move"))
	anim.flip_h = dir.x < 0

func set_idle_anim(dir: Vector2):
	anim.play(get_anim_name(dir, "idle"))
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
	return "%s_down_right" % action



# ========================================================
# Death
# ========================================================
func take_damage(a):
	health -= a
	if health <= 0:
		die()

func die():
	set_physics_process(false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	anim.play("death")
	await get_tree().create_timer(0.9).timeout
	queue_free()
