extends Node2D

@export var bullet_scene: PackedScene
@onready var muzzle: Node2D = $origin

func shoot(direction: Vector2):
	if not bullet_scene:
		push_warning("No bullet scene assigned to gun")
		return

	# Spawn bullet
	var bullet = bullet_scene.instantiate()

	# Add to main scene (recommended for projectiles)
	var world = get_tree().current_scene
	world.add_child(bullet)

	# Position bullet at muzzle
	bullet.global_position = muzzle.global_position if muzzle else global_position

	# Set direction if supported
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction.normalized())
	else:
		push_warning("Bullet scene missing set_direction() method")
