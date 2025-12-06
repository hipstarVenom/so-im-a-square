extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# --------------------------------------------------
# STATE DEFINITIONS
# --------------------------------------------------

enum {
	STATE_IDLE,
	STATE_CHASE,
	STATE_CIRCLE,
	STATE_DASH,
	STATE_BACKOFF,
	STATE_AVOID
}

var state := STATE_IDLE
var state_timer := 0.0

# --------------------------------------------------
# Enemy Settings
# --------------------------------------------------

@export var speed := 120
@export var dash_speed := 360
@export var dash_duration := 0.25
@export var backoff_speed := 200
@export var backoff_duration := 0.35

@export var max_health := 50
var health := 0

var player_body: CharacterBody2D = null

# AI Distances
var stopping_distance := 130.0
var circle_distance := 90.0
var dash_trigger_distance := 110.0  
var separation_distance := 70.0

# AI Forces
var separation_force := 250.0
var circle_strength := 150.0

# Knockback
var knockback := Vector2.ZERO
var knockback_decay := 14.0

# Bounce
var bounce_dir := Vector2.ZERO
var bounce_time := 0.0
var bounce_duration := 0.25

# Dash Logic
var dash_timer := 0.0
var dash_interval_min := 1.5
var dash_interval_max := 3.0
var dash_dir := Vector2.ZERO
var dash_time_left := 0.0

# Backoff Logic
var backoff_dir := Vector2.ZERO
var backoff_time_left := 0.0

# Smooth movement
var blend_velocity := Vector2.ZERO


# --------------------------------------------------
# INIT
# --------------------------------------------------

func _ready():
	health = max_health
	_randomize_next_dash()
	_set_state(STATE_IDLE)

	var ro = get_tree().root.find_child("player", true, false)
	if ro:
		for c in ro.get_children():
			if c is CharacterBody2D:
				player_body = c
				break


# --------------------------------------------------
# MAIN LOOP
# --------------------------------------------------

func _physics_process(delta):
	if not player_body: return

	# ------------------------
	# Global overrides
	# ------------------------
	if _handle_knockback(delta): return
	if _handle_bounce(delta): return

	state_timer -= delta

	match state:
		STATE_IDLE:    _state_idle(delta)
		STATE_CHASE:   _state_chase(delta)
		STATE_CIRCLE:  _state_circle(delta)
		STATE_DASH:    _state_dash(delta)
		STATE_BACKOFF: _state_backoff(delta)
		STATE_AVOID:   _state_avoid(delta)


# --------------------------------------------------
# STATE MACHINE CORE
# --------------------------------------------------

func _set_state(new_state:int):
	state = new_state
	state_timer = 0.3


# --------------------------------------------------
# STATE: IDLE
# --------------------------------------------------

func _state_idle(delta):
	_set_state(STATE_CHASE)


# --------------------------------------------------
# STATE: CHASE
# --------------------------------------------------

func _state_chase(delta):
	var to_player = player_body.global_position - global_position
	var dist = to_player.length()

	# ⭐ Dash immediately if too close
	if dist < dash_trigger_distance:
		_start_dash(to_player)
		return

	# circle if medium range
	if dist < stopping_distance and dist > circle_distance:
		_set_state(STATE_CIRCLE)
		return

	# avoid if extremely close
	if dist < circle_distance:
		_start_avoid()
		return

	# fallback random dash
	dash_timer -= delta
	if dash_timer <= 0:
		_start_dash(to_player)
		return

	_move_toward(to_player.normalized(), delta)


# --------------------------------------------------
# STATE: CIRCLE
# --------------------------------------------------

func _state_circle(delta):
	var to_player = player_body.global_position - global_position
	var dist = to_player.length()

	if dist > stopping_distance:
		_set_state(STATE_CHASE)
		return

	# ⭐ Dash immediately if too close (inside 110px)
	if dist < dash_trigger_distance:
		_start_dash(to_player)
		return

	# fallback random dash
	dash_timer -= delta
	if dash_timer <= 0:
		_start_dash(to_player)
		return

	var toward = to_player.normalized()
	var side = Vector2(-toward.y, toward.x)

	if not has_meta("circle_dir"):
		set_meta("circle_dir", (1 if randf() > 0.5 else -1))

	var dir = side * get_meta("circle_dir")
	_move_toward(dir, delta)


# --------------------------------------------------
# STATE: AVOID / CROWD ESCAPE
# --------------------------------------------------

func _state_avoid(delta):
	var avoid_dir = _get_crowd_avoid_dir()

	if avoid_dir.length() < 0.1:
		_set_state(STATE_CHASE)
		return

	_move_toward(avoid_dir.normalized(), delta)

	if state_timer <= 0:
		_set_state(STATE_CHASE)


# --------------------------------------------------
# STATE: DASH
# --------------------------------------------------

func _state_dash(delta):
	dash_time_left -= delta
	velocity = dash_dir * dash_speed
	move_and_slide()

	if dash_time_left <= 0:
		_start_backoff(dash_dir)


# --------------------------------------------------
# STATE: BACKOFF
# --------------------------------------------------

func _state_backoff(delta):
	backoff_time_left -= delta
	velocity = backoff_dir * backoff_speed
	move_and_slide()

	if backoff_time_left <= 0:
		_set_state(STATE_CHASE)
		_randomize_next_dash()


# --------------------------------------------------
# GLOBAL OVERRIDES
# --------------------------------------------------

func _handle_knockback(delta):
	if knockback.length() > 1:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay)
		move_and_slide()
		return true
	return false

func _handle_bounce(delta):
	if bounce_time > 0:
		bounce_time -= delta
		velocity = bounce_dir * speed
		move_and_slide()
		return true
	return false


# --------------------------------------------------
# MOVE HELPERS
# --------------------------------------------------

func _move_toward(dir:Vector2, delta):
	var desired = dir.normalized() * speed
	blend_velocity = blend_velocity.lerp(desired, delta * 6)
	velocity = blend_velocity

	var col = move_and_collide(velocity * delta)
	if col and col.get_collider().is_in_group("enemy"):
		_start_bounce()

	set_move_anim(dir)


func _get_crowd_avoid_dir() -> Vector2:
	var avoid := Vector2.ZERO

	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self: continue

		var diff = global_position - e.global_position
		var dist = diff.length()

		if dist < separation_distance * 1.8:
			avoid += diff.normalized() * (1.8 - dist/separation_distance)

	return avoid


# --------------------------------------------------
# DASH + BACKOFF
# --------------------------------------------------

func _start_dash(to_player:Vector2):
	_set_state(STATE_DASH)
	dash_time_left = dash_duration
	dash_dir = to_player.normalized()
	blend_velocity = dash_dir * dash_speed


func _start_backoff(from_dir:Vector2):
	_set_state(STATE_BACKOFF)
	backoff_time_left = backoff_duration
	backoff_dir = (-from_dir).normalized()
	blend_velocity = backoff_dir * backoff_speed


func _start_avoid():
	_set_state(STATE_AVOID)
	state_timer = 0.3


func _randomize_next_dash():
	dash_timer = randf_range(dash_interval_min, dash_interval_max)


# --------------------------------------------------
# Bounce
# --------------------------------------------------

func _start_bounce():
	bounce_dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	bounce_time = bounce_duration


# --------------------------------------------------
# ANIMATION
# --------------------------------------------------

func set_move_anim(dir: Vector2):
	anim.play(get_anim_name(dir, "move"))
	anim.flip_h = dir.x < 0

func set_idle_anim(dir: Vector2):
	anim.play(get_anim_name(dir, "idle"))
	anim.flip_h = dir.x < 0

func get_anim_name(dir: Vector2, action: String) -> String:
	if abs(dir.x) > 0.5 and abs(dir.y) < 0.5:
		return "%s_left_right" % action
	if abs(dir.x) < 0.5 and dir.y < -0.5:
		return "%s_up" % action
	if abs(dir.x) < 0.5 and dir.y > 0.5:
		return "%s_down" % action
	if dir.y < 0:
		return "%s_up_right" % action
	return "%s_down_right" % action


# --------------------------------------------------
# DAMAGE + DEATH
# --------------------------------------------------

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
