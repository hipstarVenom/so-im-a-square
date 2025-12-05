extends Area2D

@export var speed := 600
@export var lifetime := 1.0
@export var knockback_force := 120      # Knockback strength
var direction: Vector2 = Vector2.ZERO

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _ready():
	# Connect collision signals once
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	# Auto-despawn timer
	var t := Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

func _physics_process(delta: float):
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta

func _on_area_entered(_area: Area2D):
	queue_free()

func _on_body_entered(body: Node2D):
	# Ignore player
	if body.is_in_group("player"):
		return

	# Enemy hit
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(10)

		# Apply knockback if the enemy supports it
		if body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)

		queue_free()
		return

	# Walls / props
	queue_free()
