extends Node2D
@export var bullet_scene: PackedScene
@onready var muzzle: Node2D = $origin  

func shoot(direction: Vector2):
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)  # add bullet to world
	bullet.global_position = muzzle.global_position if muzzle else global_position
	bullet.direction = direction.normalized()
