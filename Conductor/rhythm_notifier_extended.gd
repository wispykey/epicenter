@tool
extends RhythmNotifier


signal beat_marker_missed

func play():
	$AudioStreamPlayer.play()

var countdown_beat: int = 0
var countdown_duration: float = 0.0

# Override to avoid resetting _position to allow clean countdown offset
func _physics_process(delta):
	if _silent_running and _stream_is_playing():
		_silent_running = false
	if not running:
		return
	if _silent_running:
		_position += delta
	else:
		_position = audio_stream_player.get_playback_position() + countdown_duration
		_position += AudioServer.get_time_since_last_mix() - _cached_output_latency
	if Engine.is_editor_hint():
		return
	for rhythm in _rhythms:
		rhythm.emit_if_needed(_position, beat_length)


func countdown(num_beats: int):
	countdown_beat = -(num_beats + 1) if num_beats > 0 else 0
	beats(1).connect(_on_countdown_beat)
	running = true


func _on_countdown_beat(_count):
	countdown_beat += 1
	if countdown_beat == 0:
		$AudioStreamPlayer.play()
		countdown_duration = _position
		
		
func get_audio_stream():
	return $AudioStreamPlayer


func emit_beat_marker_missed():
	beat_marker_missed.emit()