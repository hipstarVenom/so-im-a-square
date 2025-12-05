extends Node2D

@export var bullet_scene: PackedScene
@onready var muzzle: Node2D = $origin

func shoot(direction: Vector2):
	if bullet_scene == null:
		return

	# Instantiate bullet
	var bullet := bullet_scene.instantiate()

	# Add to world (best practice)
	get_tree().current_scene.add_child(bullet)

	# Position bullet
	bullet.global_transform = muzzle.global_transform

	# Set direction
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)
