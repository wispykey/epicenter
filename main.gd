extends Node

var outer_indicator_scene = preload("res://Circles/OuterBeatIndicator.tscn")
var inner_indicator_scene = preload("res://Circles/InnerBeatIndicator.tscn")
var beat_marker_scene = preload("res://Circles/BeatMarker.tscn")
var blip_vfx_scene = preload("res://Shaders/BlipVFX.tscn")

# HARD-CODED 4 in time signature numerator. We will not support other meters for GameOff.
const TIME_SIGNATURE_NUMERATOR: int = 4
const COUNTDOWN_OFFSET: int = 1 # in measures'
const INNER_RING_EASE: float = 0.5

var measure_time_elapsed: float = 0

const CENTER = Vector2(640, 360)
const RING_INTER_DISTANCE = 141
const FIRST_RING_DIAMETER = 297
const FIRST_RING_X = FIRST_RING_DIAMETER / 2.0

const BLIP_VFX_OFFSET = Vector2(-100, -100)

const LEFT_MARKER_QUARTER_NOTE_POSITIONS = [
	Vector2(CENTER.x + FIRST_RING_X, CENTER.y),
	Vector2(CENTER.x + FIRST_RING_X + RING_INTER_DISTANCE/2.0, CENTER.y),
	Vector2(CENTER.x + FIRST_RING_X + RING_INTER_DISTANCE/2.0 * 2.0, CENTER.y),
	Vector2(CENTER.x + FIRST_RING_X + RING_INTER_DISTANCE/2.0 * 3.0, CENTER.y),
]

const RIGHT_MARKER_QUARTER_NOTE_POSITIONS = [
	Vector2(CENTER.x - FIRST_RING_X, CENTER.y),
	Vector2(CENTER.x - FIRST_RING_X - RING_INTER_DISTANCE/2.0, CENTER.y),
	Vector2(CENTER.x - FIRST_RING_X - RING_INTER_DISTANCE/2.0 * 2.0, CENTER.y),
	Vector2(CENTER.x - FIRST_RING_X - RING_INTER_DISTANCE/2.0 * 3.0, CENTER.y),
]

const left_beatmap = {
	1: true,
	2: true,
	3: true,
	4: true
}

const right_beatmap = {
	1: true,
	2: true,
	3: true,
	4: true
}

const left_beatmap_measures = {
	1: [1],
	2: [2],
	3: [3],
	4: [4],
	5: [1,2],
	6: [3,4],
	7: [1,4],
	8: [2,3]
}

var current_beatmap: BeatMap
var left_side_spawn_timings = {}
var right_side_spawn_timings = {}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hit_ring1_right"):
		print("HIT Ring1 R")
		# Check if there is a beat marker currently there
		# If so, remove the least recently added one (there may be multiple)
			# And, compute score based on input timing relative to the beat
		# Otherwise, play some sort of 'oops' noise and VFX

		var radar_blip = blip_vfx_scene.instantiate()
		radar_blip.position = LEFT_MARKER_QUARTER_NOTE_POSITIONS[0] + BLIP_VFX_OFFSET
		add_child(radar_blip)
	if event.is_action_pressed("hit_ring1_left"):
		print("HIT Ring1 L")
		var radar_blip = blip_vfx_scene.instantiate()
		radar_blip.position = RIGHT_MARKER_QUARTER_NOTE_POSITIONS[0] + BLIP_VFX_OFFSET
		add_child(radar_blip)

	
		

func _ready() -> void:
	Conductor.beats(0.0625).connect(_on_sixteenth_notes_update_time_elapsed)
	Conductor.beats(4).connect(_on_downbeat_reset_time_elapsed)
	Conductor.beats(4).connect(_on_third_beat_spawn_next_indicator)
	Conductor.beats(4).connect(_on_measure_start_spawn_beat_markers)
	
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
		var t = marker.measure_time_elapsed / (measure_length)
		var lerp_progress = lerp(marker.start_scale.x, marker.end_scale.x, t)
		var new_scale = lerp_progress
		var new_opacity = ease(t, 0.4)
		marker.indicator.scale = Vector2(new_scale, new_scale)
		marker.indicator.self_modulate.a = new_opacity
		# marker.self_modulate.a = new_opacity * 1.4


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
	
	
func _on_measure_start_spawn_beat_markers(_count):
	# Shift to 1-indexing (RhythmNotifier uses 0-indexing)
	var current_measure = floori((Conductor.current_beat) / 4.0) + 1

	# Looping allows a single measure to be defined for the whole song
	# TODO: Allow defining multiple loops, to match different sections of a song (?)
	if current_beatmap.is_looping:
		for marker_timing in right_side_spawn_timings.get(1):
			var marker = beat_marker_scene.instantiate()
			marker.position = RIGHT_MARKER_QUARTER_NOTE_POSITIONS[marker_timing - 1]
			$BeatMarkers.add_child(marker)
		for marker_timing in left_side_spawn_timings.get(1):
			var marker = beat_marker_scene.instantiate()
			marker.position = LEFT_MARKER_QUARTER_NOTE_POSITIONS[marker_timing - 1]
			$BeatMarkers.add_child(marker)

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
