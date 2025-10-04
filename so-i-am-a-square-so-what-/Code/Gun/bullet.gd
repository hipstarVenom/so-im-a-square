extends Area2D

@export var speed := 500
var direction: Vector2 = Vector2.ZERO

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _physics_process(delta: float):
	position += direction * speed * delta

	# Remove if off-screen
	if not get_viewport_rect().has_point(global_position):
		queue_free()
