extends Sprite2D

var measure_time_elapsed: float = 0
var start_scale: Vector2 = Vector2.ZERO
var end_scale: Vector2 = Vector2.ONE
var extra_duration_ratio: float = 1.0

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if scale.x >= end_scale.x: #lmao
		queue_free()
