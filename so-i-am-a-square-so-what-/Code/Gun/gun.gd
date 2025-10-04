extends Node2D  # Gun is Node2D

@export var bullet: PackedScene
@onready var origin: Node2D = $origin

func shoot(direction: Vector2):
	if not bullet:
		return

	var bullet_instance = bullet.instantiate() as Area2D
	get_parent().add_child(bullet_instance)

	# Spawn at gun origin
	bullet_instance.global_position = origin.global_position

	# Set bullet direction
	if bullet_instance.has_method("set_direction"):
		bullet_instance.set_direction(direction)
