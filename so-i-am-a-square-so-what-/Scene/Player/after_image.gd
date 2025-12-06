extends Node2D

@export var fade_time := 0.125
@export var start_alpha := 0.9

func _ready():
	# Start visible
	modulate.a = start_alpha
	self_modulate.a = start_alpha

	var tween := create_tween()

	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.parallel().tween_property(self, "self_modulate:a", 0.0, fade_time)

	# When done → delete the ghost
	tween.finished.connect(func():
		queue_free()
	)
