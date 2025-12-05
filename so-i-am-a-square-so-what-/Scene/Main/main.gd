extends Node2D

@export var monster_scene_1: PackedScene
@export var monster_scene_2: PackedScene
@export var player: Node2D

@export var base_spawn_interval := 2.0
@export var min_spawn_interval := 0.4
@export var spawn_interval_reduce_rate := 0.02

@export var enemy_speed_increase := 2.0
@export var enemy_hp_increase := 1.0

@export var group_size_start := 1
@export var group_size_max := 5

@export var spawn_distance_from_screen := 40.0
@export var player_safe_distance := 150.0

var current_spawn_interval := 0.0
var difficulty_timer := 0.0

var timer: Timer


func _ready():
	current_spawn_interval = base_spawn_interval

	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = current_spawn_interval
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_spawn_group)


func _process(delta):
	difficulty_timer += delta

	current_spawn_interval = max(
		min_spawn_interval,
		base_spawn_interval - difficulty_timer * spawn_interval_reduce_rate
	)

	timer.wait_time = current_spawn_interval


func _spawn_group():
	var group_size = clamp(
		group_size_start + int(difficulty_timer / 8),
		group_size_start,
		group_size_max
	)

	for i in range(group_size):
		_spawn_single_enemy()


func _spawn_single_enemy():
	var scene = pick_random_scene()
	if scene == null:
		return

	var enemy = scene.instantiate()
	enemy.global_position = pick_spawn_position()

	# Use apply_difficulty() if enemy supports it
	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(
			difficulty_timer * enemy_speed_increase,
			int(difficulty_timer * enemy_hp_increase)
		)

	get_tree().current_scene.add_child(enemy)


func pick_random_scene() -> PackedScene:
	return monster_scene_1 if randf() < 0.5 else monster_scene_2


func pick_spawn_position() -> Vector2:
	var rect = get_viewport().get_visible_rect()
	var mode = randi() % 3

	match mode:
		0:
			return spawn_in_corners(rect)
		1:
			return spawn_on_edges(rect)
		2:
			return spawn_off_screen(rect)

	return Vector2.ZERO


func spawn_in_corners(rect: Rect2) -> Vector2:
	var corners = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + Vector2(0, rect.size.y),
		rect.position + rect.size
	]
	return corners.pick_random()


func spawn_on_edges(rect: Rect2) -> Vector2:
	var side = randi() % 4

	match side:
		0:
			return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y)
		1:
			return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x),
				rect.position.y + rect.size.y)
		2:
			return Vector2(rect.position.x,
				randf_range(rect.position.y, rect.position.y + rect.size.y))
		3:
			return Vector2(rect.position.x + rect.size.x,
				randf_range(rect.position.y, rect.position.y + rect.size.y))

	return Vector2.ZERO


func spawn_off_screen(rect: Rect2) -> Vector2:
	var side = randi() % 4
	var offset = spawn_distance_from_screen

	match side:
		0:
			return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x),
				rect.position.y - offset)
		1:
			return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x),
				rect.position.y + rect.size.y + offset)
		2:
			return Vector2(rect.position.x - offset,
				randf_range(rect.position.y, rect.position.y + rect.size.y))
		3:
			return Vector2(rect.position.x + rect.size.x + offset,
				randf_range(rect.position.y, rect.position.y + rect.size.y))

	return Vector2.ZERO
