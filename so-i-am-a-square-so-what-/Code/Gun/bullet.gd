extends Area2D

@export var speed := 500
var direction: Vector2 = Vector2.ZERO

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _physics_process(delta: float):
	# Move bullet
	if direction != Vector2.ZERO:
		position += direction * speed * delta

	# Remove if off-screen (camera-aware)
	var camera = get_viewport().get_camera_2d()
	if camera:
		var screen_rect = Rect2(camera.global_position - camera.zoom * camera.get_viewport_rect().size / 2,
								camera.get_viewport_rect().size * camera.zoom)
		if not screen_rect.has_point(global_position):
			queue_free()
