extends Node2D

@export var bullet_scene: PackedScene
@onready var muzzle: Node2D = $origin  

func shoot(direction: Vector2):
	if not bullet_scene:
		push_warning("No bullet scene assigned to gun")
		return
	
	var bullet = bullet_scene.instantiate()
	
	# Add bullet to the current scene
	get_parent().get_parent().add_child(bullet)
	
	# Set bullet position and direction
	bullet.global_position = muzzle.global_position if muzzle else global_position
	
	# Make sure the bullet has the set_direction method
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction.normalized())
	else:
		push_warning("Bullet scene doesn't have set_direction method")
