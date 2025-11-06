extends Sprite2D

@onready var indicator := $TimingRing

var extra_duration_ratio = 1.5
var measure_time_elapsed = 0.0
var start_scale = Vector2(6.0, 6.0)
var end_scale = Vector2.ONE

# Hard-coded to one measure at 120 BPM
var base_wait_time: float = 2.0

func _ready() -> void:
	$Timer.wait_time = 2.0 * extra_duration_ratio
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()
	
	
func _on_timer_timeout():
	queue_free()
