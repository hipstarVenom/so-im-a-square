extends Area2D

@export var speed := 500
var direction: Vector2 = Vector2.ZERO
var lifetime := 5.0  # Bullet lifetime in seconds

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _ready():
	# Connect area entered signal for collision detection
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Set up lifetime timer
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_end)
	add_child(timer)
	timer.start()

func _physics_process(delta: float):
	# Move bullet
	if direction != Vector2.ZERO:
		position += direction * speed * delta

func _on_area_entered(area: Area2D):
	# Handle collision with other areas
	queue_free()

func _on_body_entered(body: Node2D):
	# Handle collision with physics bodies (except player)
	if not body.is_in_group("player"):
		queue_free()

func _on_lifetime_end():
	# Remove bullet after lifetime expires
	queue_free()
