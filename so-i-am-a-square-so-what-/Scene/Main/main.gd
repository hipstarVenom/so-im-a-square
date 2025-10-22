extends Node2D

# Assign your monster scenes
@export var monster_scene_1: PackedScene
@export var monster_scene_2: PackedScene

# Reference to player node
@export var player: Node2D

# Spawn intervals
@export var spawn_interval_1: float = 15.0
@export var spawn_interval_2: float = 30.0

# Margin from edges
@export var edge_margin: float = 50.0  # pixels from edges
@export var player_safe_distance: float = 100.0  # pixels away from player

var timer1: Timer
var timer2: Timer

func _ready():
	# Timer for monster 1
	timer1 = Timer.new()
	timer1.wait_time = spawn_interval_1
	timer1.one_shot = false
	timer1.autostart = true
	add_child(timer1)
	timer1.timeout.connect(Callable(self, "_spawn_monster_1"))
	
	# Timer for monster 2
	timer2 = Timer.new()
	timer2.wait_time = spawn_interval_2
	timer2.one_shot = false
	timer2.autostart = true
	add_child(timer2)
	timer2.timeout.connect(Callable(self, "_spawn_monster_2"))

func _spawn_monster_1():
	_spawn_monster(monster_scene_1)

func _spawn_monster_2():
	_spawn_monster(monster_scene_2)

func _spawn_monster(monster_scene: PackedScene):
	var monster_instance = monster_scene.instantiate()
	var viewport_size = get_viewport_rect().size
	
	var spawn_position = Vector2.ZERO
	var tries = 0
	# Keep trying random positions until it is far enough from player
	while tries < 50:
		var x = randf_range(edge_margin, viewport_size.x - edge_margin)
		var y = randf_range(edge_margin, viewport_size.y - edge_margin)
		spawn_position = Vector2(x, y)
		if player == null or spawn_position.distance_to(player.position) >= player_safe_distance:
			break
		tries += 1
	
	monster_instance.position = spawn_position
	get_parent().add_child(monster_instance)
