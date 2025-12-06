extends Node2D

#
# ============================
#     EXPORT VARIABLES
# ============================
#

@export var monster_scene_1: PackedScene
@export var monster_scene_2: PackedScene
@export var player: Node2D

@export var offscreen_margin: float = 180.0
@export var max_enemies: int = 21       # HARD LIMIT


#
# ============================
#     INTERNAL STATE
# ============================
#

var next_wave_size: int = 2             # Start at 2
var max_wave_size: int = 15             # End at 15
var enemy_count: int = 0
var camera: Camera2D


#
# ============================
#            READY
# ============================
#

func _ready() -> void:
	await get_tree().process_frame

	camera = _find_camera_in_player(player)

	if camera == null:
		push_error("Spawner ERROR: Camera2D not found inside Player!")
		return

	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)


#
# ============================
#     FIND CAMERA 
# ============================
#

func _find_camera_in_player(node):
	if node is Camera2D:
		return node

	for c in node.get_children():
		var r = _find_camera_in_player(c)
		if r != null:
			return r

	return null


#
# ============================
#     PROCESS (Wave Logic)
# ============================
#

func _process(delta: float) -> void:
	# Do not spawn next wave until current wave is dead
	if enemy_count > 0:
		return

	# If enemies somehow exceed limit, pause waves
	if enemy_count >= max_enemies:
		return

	# Spawn next wave
	_spawn_wave(next_wave_size)

	# Increase wave size (up to 15 max)
	if next_wave_size < max_wave_size:
		next_wave_size += 1
	else:
		next_wave_size = max_wave_size   # hold at 15


#
# ============================
#     SPAWN WAVE
# ============================
#

func _spawn_wave(count: int):
	var base_pos = pick_spawn_position()

	for i in range(count):
		_spawn_enemy(base_pos, i)


func _spawn_enemy(base_pos: Vector2, index: int):
	if enemy_count >= max_enemies:
		return

	var scene := pick_random_scene()
	if scene == null:
		return

	var enemy: Node2D = scene.instantiate()

	# spread pattern
	var angle := randf_range(-0.6, 0.6) + float(index) * 0.35
	var offset := Vector2(140, 0).rotated(angle)

	enemy.global_position = base_pos + offset

	get_tree().current_scene.add_child(enemy)


#
# ============================
#     RANDOM SCENE PICK
# ============================
#

func pick_random_scene() -> PackedScene:
	return monster_scene_1 if randf() < 0.5 else monster_scene_2


#
# ============================
#     CAMERA-BASED SPAWN
# ============================
#

func pick_spawn_position() -> Vector2:
	var cam_pos: Vector2 = camera.global_position
	var viewport_rect := get_viewport().get_visible_rect()
	var viewport_size := Vector2(viewport_rect.size)
	var half := viewport_size * 0.5
	var rect := Rect2(cam_pos - half, viewport_size)

	var side := randi() % 4

	match side:
		0:
			return Vector2(randf_range(rect.position.x, rect.end.x),
				rect.position.y - offscreen_margin)
		1:
			return Vector2(randf_range(rect.position.x, rect.end.x),
				rect.end.y + offscreen_margin)
		2:
			return Vector2(rect.position.x - offscreen_margin,
				randf_range(rect.position.y, rect.end.y))
		3:
			return Vector2(rect.end.x + offscreen_margin,
				randf_range(rect.position.y, rect.end.y))

	return cam_pos


#
# ============================
#     ENEMY COUNT (FAST O(1))
# ============================
#

func _on_node_added(node):
	if node.is_in_group("enemy"):
		enemy_count += 1

func _on_node_removed(node):
	if node.is_in_group("enemy"):
		enemy_count = max(0, enemy_count - 1)
