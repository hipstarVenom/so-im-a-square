extends Area2D

@export var speed := 600
@export var lifetime := 1.0
@export var knockback_force := 120

var direction := Vector2.ZERO


func set_direction(dir: Vector2):
	direction = dir.normalized()


func _ready():
	# Connect signals once
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

	# Despawn timer
	var t := Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	add_child(t)
	t.timeout.connect(queue_free)
	t.start()


func _physics_process(delta: float):
	global_position += direction * speed * delta


func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		return

	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(10)

		if body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)

	queue_free()
