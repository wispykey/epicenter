extends Sprite2D

@onready var indicator := $BeatMarkerIndicatorRing

var extra_duration_ratio = 1.5
var measure_time_elapsed = 0.0
var start_scale = Vector2(6.0, 6.0)
var end_scale = Vector2.ONE

const min_r_pos: float = 0.05
const max_r_pos: float = 0.45

# Hard-coded to one measure at 120 BPM
var base_wait_time: float = 2.0

func _ready() -> void:
	$Timer.wait_time = 2.0 * extra_duration_ratio
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()
	indicator.material = indicator.material.duplicate()
	
	
func _on_timer_timeout():
	Conductor.emit_beat_marker_missed()
	queue_free()

func update_shader_parameters(t: float):
	# Radial start position of ring
	var t_for_radius = 1 - (ease(t, 0.8))
	var r = lerp(min_r_pos, max_r_pos, t_for_radius)
	indicator.material.set_shader_parameter("r", r)

	# Opacity
	var t_for_opacity = ease(t, 0.3)
	indicator.material.set_shader_parameter("opacity", t_for_opacity)
