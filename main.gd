extends Node

var outer_indicator_scene = preload("res://Circles/OuterBeatIndicator.tscn")
var inner_indicator_scene = preload("res://Circles/InnerBeatIndicator.tscn")
var beat_marker_scene = preload("res://Circles/BeatMarker.tscn")
var blip_vfx_scene = preload("res://Shaders/BlipVFX.tscn")

# HARD-CODED 4 in time signature numerator. We will not support other meters for GameOff.
const TIME_SIGNATURE_NUMERATOR: int = 4
const COUNTDOWN_OFFSET: int = 1 # in measures'
const INNER_RING_EASE: float = 0.5

const MINIMUM_LIFETIME_BEFORE_DESTRUCTIBLE: float = 0.5

# Increase above 1.0 to have correct timing align with a larger indicator ring state
# Maybe should be a constant instead of multiplier?
const BEAT_MARKER_TIMING_CALIBRATION_MULTIPLIER: float = 1.05
const BLIP_VFX_MISS_COLOR = Color(0.0, 1.0, 1.0, 1.0)

var measure_time_elapsed: float = 0

const CENTER = Vector2(640, 360)
const RING_INTER_DISTANCE = 141
const FIRST_RING_DIAMETER = 297
const FIRST_RING_X = FIRST_RING_DIAMETER / 2.0

const BLIP_VFX_OFFSET = Vector2(-100, -100)

const RIGHT_MARKER_QUARTER_NOTE_POSITIONS = [
	Vector2(CENTER.x + FIRST_RING_X, CENTER.y),
	Vector2(CENTER.x + FIRST_RING_X + RING_INTER_DISTANCE/2.0, CENTER.y),
	Vector2(CENTER.x + FIRST_RING_X + RING_INTER_DISTANCE/2.0 * 2.0, CENTER.y),
	Vector2(CENTER.x + FIRST_RING_X + RING_INTER_DISTANCE/2.0 * 3.0, CENTER.y),
]

const LEFT_MARKER_QUARTER_NOTE_POSITIONS = [
	Vector2(CENTER.x - FIRST_RING_X, CENTER.y),
	Vector2(CENTER.x - FIRST_RING_X - RING_INTER_DISTANCE/2.0, CENTER.y),
	Vector2(CENTER.x - FIRST_RING_X - RING_INTER_DISTANCE/2.0 * 2.0, CENTER.y),
	Vector2(CENTER.x - FIRST_RING_X - RING_INTER_DISTANCE/2.0 * 3.0, CENTER.y),
]

var current_beatmap: BeatMap
var left_side_spawn_timings = {}
var right_side_spawn_timings = {}


@onready var input_to_collision_area_dict = {
	"hit_ring1_right": $CollisionZones/Ring1Right,
	"hit_ring2_right": $CollisionZones/Ring2Right,
	"hit_ring3_right": $CollisionZones/Ring3Right,
	"hit_ring4_right": $CollisionZones/Ring4Right,
	"hit_ring1_left": $CollisionZones/Ring1Left,
	"hit_ring2_left": $CollisionZones/Ring2Left,
	"hit_ring3_left": $CollisionZones/Ring3Left,
	"hit_ring4_left": $CollisionZones/Ring4Left,
}


func _input(event: InputEvent) -> void:

	for input in input_to_collision_area_dict:
		if event.is_action_pressed(input):
			var collision_area = input_to_collision_area_dict[input]
			var marker_areas: Array[Area2D] = collision_area.get_overlapping_areas()

			# Commented-out code to find the longest-living marker to remove first, if needed

			# var reduce_func = func compare_lifetime(accum, area):
			# 	if area.owner.measure_time_elapsed > accum.owner.measure_time_elapsed:
			# 		return area
			# 	else:
			# 		return accum

			var radar_blip = blip_vfx_scene.instantiate()

			# HARD-CODED string parsing of input names...
			var which_ring = input.split("_")[1]
			if not which_ring: return
			# Shift from 1-index to 0-index
			var ring_index = int(which_ring[-1]) - 1

			if "left" in input:
				radar_blip.position = LEFT_MARKER_QUARTER_NOTE_POSITIONS[ring_index] + BLIP_VFX_OFFSET
			else:
				radar_blip.position = RIGHT_MARKER_QUARTER_NOTE_POSITIONS[ring_index] + BLIP_VFX_OFFSET



			if marker_areas.size() > 0 and marker_areas[0].owner.measure_time_elapsed > MINIMUM_LIFETIME_BEFORE_DESTRUCTIBLE:
				# var marker_area_to_remove = marker_areas.reduce(reduce_func, marker_areas[0])
				# marker_area_to_remove.owner.queue_free()
				marker_areas[0].owner.queue_free()
			else:
				radar_blip.modulate = BLIP_VFX_MISS_COLOR

			add_child(radar_blip)
		

func _ready() -> void:
	Conductor.beats(0.0625).connect(_on_sixteenth_notes_update_time_elapsed)
	Conductor.beats(4).connect(_on_downbeat_reset_time_elapsed)
	Conductor.beats(4).connect(_on_third_beat_spawn_next_indicator)
	Conductor.beats(1).connect(_on_quarter_beat_spawn_beat_markers)
	
	init_ring_pulses()
	
	current_beatmap = load("res://Beatmaps/all_downbeats_beatmap.tres")
	compute_spawn_timings()
	
	Conductor.countdown(4)
	
	
func _process(_delta: float) -> void:
	update_indicators()

func _physics_process(_delta: float) -> void:
	update_debug_info()


func init_ring_pulses():
	Conductor.beats(4, true, 0).connect(_on_first_beat_pulse_ring1)
	Conductor.beats(4, true, 1).connect(_on_second_beat_pulse_ring2)
	Conductor.beats(4, true, 2).connect(_on_third_beat_pulse_ring3)
	Conductor.beats(4, true, 3).connect(_on_fourth_beat_pulse_ring4)


func update_debug_info():
	$PositionLabel.text = "_position: %.3f" % Conductor._position
	$CountdownLabel.text = "playback: %.3f" % Conductor.audio_stream_player.get_playback_position()
	$TimeSinceLastMixLabel.text = "last_mix: %.3f" % AudioServer.get_time_since_last_mix()
	$CachedLatencyLabel.text = "cached: %.3f" % Conductor._cached_output_latency



func compute_spawn_timings():
	
	for timing in current_beatmap.left_side_timings:
		left_side_spawn_timings[timing] = current_beatmap.left_side_timings[timing]
		
	for timing in current_beatmap.right_side_timings:
		right_side_spawn_timings[timing] = current_beatmap.right_side_timings[timing]


func play_pulse_animation_tween(node: Node2D):
	var tween = create_tween()
	
	tween.tween_property(node, "scale", Vector2(1.15, 1.15), 0.15)
	tween.chain().tween_property(node, "scale", Vector2.ONE, 0.1)
	
	tween.play()


func _on_first_beat_pulse_ring1(_count):
	play_pulse_animation_tween($Ring1)
	
	
func _on_second_beat_pulse_ring2(_count):
	play_pulse_animation_tween($Ring2)
	
	
func _on_third_beat_pulse_ring3(_count):
	play_pulse_animation_tween($Ring3)

	
func _on_fourth_beat_pulse_ring4(_count):
	play_pulse_animation_tween($Ring4)


func update_indicators():
	var measure_length = Conductor.beat_length * TIME_SIGNATURE_NUMERATOR
	
	for indicator in $OuterBeatIndicators.get_children():
		var t = indicator.measure_time_elapsed / (measure_length * indicator.extra_duration_ratio)
		var new_scale = indicator.start_scale.x + lerp(0.0, indicator.end_scale.x, t)
		indicator.scale = Vector2(new_scale, new_scale)
		
	for indicator in $InnerBeatIndicators.get_children():
		var t = indicator.measure_time_elapsed / (measure_length * indicator.extra_duration_ratio)
		var lerp_output = lerp(0.0, indicator.end_scale.x, t)
		var eased_lerp_output = ease(lerp_output, INNER_RING_EASE)
		var new_scale = indicator.start_scale.x + eased_lerp_output
		indicator.scale = Vector2(new_scale, new_scale)
		
	for marker in $BeatMarkers.get_children():
		var t = marker.measure_time_elapsed / (measure_length * BEAT_MARKER_TIMING_CALIBRATION_MULTIPLIER)
		t = clamp(t, 0, 1)

		# Scale-based GradientTexture2D approach
		# var lerp_progress = lerp(marker.start_scale.x, marker.end_scale.x, ease(t, 0.6))
		# var new_scale = lerp_progress
		# marker.indicator.scale = Vector2(new_scale, new_scale)

		# Shader + shader parameter approach
		marker.update_shader_parameters(t)

		var new_opacity = ease(t, 0.4)
		# marker.indicator.self_modulate.a = new_opacity
		marker.self_modulate.a = new_opacity * 1.4


func _on_sixteenth_notes_update_time_elapsed(_count):
	var step = (Conductor.beat_length / 16.0)
	for indicator in $InnerBeatIndicators.get_children():
		indicator.measure_time_elapsed += step
	for indicator in $OuterBeatIndicators.get_children():
		indicator.measure_time_elapsed += step
	for indicator in $BeatMarkers.get_children():
		indicator.measure_time_elapsed += step
	measure_time_elapsed += step
	
	
func _on_downbeat_reset_time_elapsed(_count):
	measure_time_elapsed = 0
	var new_indicator = outer_indicator_scene.instantiate()
	new_indicator.position = CENTER
	$OuterBeatIndicators.add_child(new_indicator)


func _on_third_beat_spawn_next_indicator(_count):
	var new_indicator = inner_indicator_scene.instantiate()
	new_indicator.position = CENTER
	new_indicator.scale = Vector2.ZERO
	$InnerBeatIndicators.add_child(new_indicator)
	
	
func _on_quarter_beat_spawn_beat_markers(_count):
	# Shift to 1-indexing (RhythmNotifier uses 0-indexing)
	var current_measure = floori((Conductor.current_beat) / 4.0) + 1
	# Also 0-indexed, 0-1-2-3 in 4/4
	var current_beat_in_measure = Conductor.current_beat % 4

	# Looping allows a single measure to be defined for the whole song
	# TODO: Allow defining multiple loops, to match different sections of a song (?)
	if current_beatmap.is_looping:
		# Instead of looping, we want to attempt a lookup of current 0-indexed beat
		# Lookup will always be successful, but there may or may not be contents
		var marker_timing = right_side_spawn_timings.get(1)[current_beat_in_measure]
		var marker = beat_marker_scene.instantiate()
		marker.position = RIGHT_MARKER_QUARTER_NOTE_POSITIONS[marker_timing - 1]
		$BeatMarkers.add_child(marker)

		var left_marker_timing = left_side_spawn_timings.get(1)[current_beat_in_measure]
		var left_marker = beat_marker_scene.instantiate()
		left_marker.position = LEFT_MARKER_QUARTER_NOTE_POSITIONS[left_marker_timing - 1]
		$BeatMarkers.add_child(left_marker)



		# for marker_timing in left_side_spawn_timings.get(1):
		# 	var marker = beat_marker_scene.instantiate()
		# 	marker.position = LEFT_MARKER_QUARTER_NOTE_POSITIONS[marker_timing - 1]
		# 	$BeatMarkers.add_child(marker)

	else:	
		if current_measure in right_side_spawn_timings:
			for marker_timing in right_side_spawn_timings[current_measure]:
				var marker = beat_marker_scene.instantiate()
				marker.position = RIGHT_MARKER_QUARTER_NOTE_POSITIONS[marker_timing - 1]
				$BeatMarkers.add_child(marker)
		if current_measure in left_side_spawn_timings:
			for marker_timing in left_side_spawn_timings[current_measure]:
				var marker = beat_marker_scene.instantiate()
				marker.position = LEFT_MARKER_QUARTER_NOTE_POSITIONS[marker_timing - 1]
				$BeatMarkers.add_child(marker)
