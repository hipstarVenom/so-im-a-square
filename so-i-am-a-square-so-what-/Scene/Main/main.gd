extends Node2D

@export var monster_scene_1: PackedScene
@export var monster_scene_2: PackedScene
@export var player: Node2D

@export var base_spawn_interval := 2.4
@export var min_spawn_interval := 1.0
@export var spawn_interval_reduce_rate := 0.005

@export var enemy_speed_increase := 0.5
@export var enemy_hp_increase := 0.5

@export var group_size_start := 1
@export var group_size_max := 3

@export var spawn_distance_from_screen := 60.0
@export var player_safe_distance := 260.0
@export var enemy_spacing := 120.0

@export var max_enemies_on_screen := 15

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
	if get_enemy_count() >= max_enemies_on_screen:
		return

	var group_size = clamp(
		group_size_start + int(difficulty_timer / 20),
		group_size_start,
		group_size_max
	)

	var base_position = pick_spawn_position()

	for i in range(group_size):
		_spawn_single_enemy(base_position, i)


func _spawn_single_enemy(base_position: Vector2, index: int):
	var scene = pick_random_scene()
	if scene == null:
		return

	var enemy = scene.instantiate()

	var angle = (float(index) * 0.9) + randf_range(-0.4, 0.4)
	var offset = Vector2(enemy_spacing, 0).rotated(angle * TAU)

	enemy.global_position = base_position + offset

	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(
			difficulty_timer * enemy_speed_increase,
			int(difficulty_timer * enemy_hp_increase)
		)

	get_tree().current_scene.add_child(enemy)


func pick_random_scene() -> PackedScene:
	return monster_scene_1 if randf() < 0.5 else monster_scene_2


# FIXED: pick_spawn_position ALWAYS returns a value
func pick_spawn_position() -> Vector2:
	var rect = get_viewport().get_visible_rect()
	var spawn_position := Vector2.ZERO

	var attempts := 0

	while attempts < 50:
		var mode = randi() % 3

		match mode:
			0: spawn_position = spawn_in_corners(rect)
			1: spawn_position = spawn_on_edges(rect)
			2: spawn_position = spawn_off_screen(rect)

		if spawn_position.distance_to(player.global_position) >= player_safe_distance:
			return spawn_position

		attempts += 1

	# Fallback (center of screen)
	return rect.position + rect.size * 0.5


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
		0: return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y)
		1: return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y + rect.size.y)
		2: return Vector2(rect.position.x, randf_range(rect.position.y, rect.position.y + rect.size.y))
		3: return Vector2(rect.position.x + rect.size.x, randf_range(rect.position.y, rect.position.y + rect.size.y))

	return rect.position  # fallback


func spawn_off_screen(rect: Rect2) -> Vector2:
	var side = randi() % 4
	var offset = spawn_distance_from_screen

	match side:
		0:
			return Vector2(
				randf_range(rect.position.x, rect.position.x + rect.size.x),
				rect.position.y - offset
			)
		1:
			return Vector2(
				randf_range(rect.position.x, rect.position.x + rect.size.x),
				rect.position.y + rect.size.y + offset
			)
		2:
			return Vector2(
				rect.position.x - offset,
				randf_range(rect.position.y, rect.position.y + rect.size.y)
			)
		3:
			return Vector2(
				rect.position.x + rect.size.x + offset,
				randf_range(rect.position.y, rect.position.y + rect.size.y)
			)

	return rect.position  # fallback


func get_enemy_count() -> int:
	var count := 0

	for child in get_tree().current_scene.get_children():
		if child.is_in_group("enemy"):
			count += 1

	return count
