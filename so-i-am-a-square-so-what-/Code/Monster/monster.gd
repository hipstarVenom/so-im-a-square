extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var speed := 100
@export var max_health := 50
var health := max_health

var player_body: CharacterBody2D = null


func _ready():
	var player_root = get_tree().get_root().find_child("player", true, false)
	if player_root:
		# Find the first CharacterBody2D inside Player
		for child in player_root.get_children():
			if child is CharacterBody2D:
				player_body = child
				break
	
	if not player_body:
		push_warning("⚠️ Could not find CharacterBody2D inside Player node!")

	
	set_idle_anim(Vector2.DOWN)

func _physics_process(_delta):
	if not player_body:
		return

	# Get direction to player's CharacterBody2D
	var direction = (player_body.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# Animate according to movement
	if velocity.length() > 0.1:
		set_move_anim(direction)
	else:
		set_idle_anim(direction)

# ======================
# Animation helpers
# ======================
func set_move_anim(dir: Vector2):
	var anim_name := get_anim_name(dir, "move")
	anim.play(anim_name)
	apply_flip(dir)

func set_idle_anim(dir: Vector2):
	var anim_name := get_anim_name(dir, "idle")
	anim.play(anim_name)
	apply_flip(dir)

func apply_flip(dir: Vector2):
	anim.flip_h = dir.x < 0

func get_anim_name(dir: Vector2, action: String) -> String:
	if abs(dir.x) > 0.5 and abs(dir.y) < 0.5:
		return "%s_left_right" % action
	elif abs(dir.x) < 0.5 and dir.y < -0.5:
		return "%s_up" % action
	elif abs(dir.x) < 0.5 and dir.y > 0.5:
		return "%s_down" % action
	elif dir.y < 0:
		return "%s_up_right" % action
	else:
		return "%s_down_right" % action

# ======================
# Damage and death
# ======================
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	set_physics_process(false)
	set_process(false)
	velocity = Vector2.ZERO

	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)  

	anim.play("death")
	await get_tree().create_timer(1.0).timeout
	call_deferred("queue_free")  
