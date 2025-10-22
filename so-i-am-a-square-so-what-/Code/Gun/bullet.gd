extends Area2D

@export var speed := 500
var direction: Vector2 = Vector2.ZERO
@export var lifetime := 5.0  # Bullet lifetime in seconds

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _ready():
	# Connect signals safely (prevents duplicate connection errors)
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	# Lifetime timer to remove the bullet automatically
	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_end)
	add_child(timer)
	timer.start()

func _physics_process(delta: float):
	# Move bullet continuously
	if direction != Vector2.ZERO:
		position += direction * speed * delta

func _on_area_entered(_area: Area2D):
	# Handle collision with other areas (like shields or triggers)
	queue_free()

func _on_body_entered(body: Node2D):
	# Ignore hitting the player who fired this bullet (if tagged)
	if body.is_in_group("player") or body.is_in_group("enemy"):
		# Example: you could deal damage here instead of freeing the body
		if body.has_method("take_damage"):
			body.take_damage(10)
		queue_free()
	else:
		# For walls or other objects
		queue_free()

func _on_lifetime_end():
	queue_free()
