extends Sprite2D

@onready var indicator := $TimingRing

var extra_duration_ratio = 1.0
var measure_time_elapsed = 0.0
var start_scale = Vector2(6.0, 6.0)
var end_scale = Vector2(1.0, 1.0)

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	
	
func _on_timer_timeout():
	queue_free()
