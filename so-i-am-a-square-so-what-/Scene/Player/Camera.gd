extends Camera2D

@onready var map_area := get_tree().get_root().get_node("main/MapArea")

func _ready():

	var map_pos = map_area.global_position
	var map_size = map_area.size
	var map_end = map_pos + map_size

	# Set camera limits to map borders
	limit_left = map_pos.x
	limit_top = map_pos.y
	limit_right = map_end.x
	limit_bottom = map_end.y
