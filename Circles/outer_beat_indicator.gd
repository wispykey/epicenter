extends Sprite2D

var measure_time_elapsed: float = 0
var start_scale: Vector2 = Vector2.ONE
var end_scale: Vector2 = Vector2(3.0, 3.0)
var extra_duration_ratio: float = 1.5

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if scale.x > 6.0: #lmao
		queue_free()
