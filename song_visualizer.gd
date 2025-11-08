extends Control

# Adapted from https://github.com/dannyboy1044/GodotAudioVisualizerExample/blob/main/basic_bars_example.gd

var audio_stream_to_visualize: AudioStreamPlayer
var spectrum_instance

const NUM_BARS: int = 64
const MAX_FREQUENCY: float = 5000.0
const MIN_Y_HEIGHT: float = 0.1
const BAR_SPACING_RATIO: float = 0.8
var bars = []

var gradient: Gradient

func _ready() -> void:
	audio_stream_to_visualize = Conductor.get_audio_stream()
	spectrum_instance = AudioServer.get_bus_effect_instance(1, 0)

	# scale = Vector2(1.5, 1.5)

	create_color_gradient()
	create_bars()


func create_color_gradient():
	gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 1.0, 0.8, 0.5))
	gradient.add_point(0.5, Color(0.6, 0.2, 1.0, 0.5))
	gradient.add_point(1.0, Color(1.0, 0.2, 0.2, 0.5))


func create_bars():
	var bar_width = 1280 / NUM_BARS / 2
	for i in range(NUM_BARS * 2):
		var bar = ColorRect.new()
		bar.color = Color(0.2, 0.8, 1.0)
		bar.size = Vector2(bar_width * BAR_SPACING_RATIO, 50)
		bar.position = Vector2(i * bar_width, 0)
		add_child(bar)
		bars.append(bar)


func _physics_process(_delta: float) -> void:
	if not spectrum_instance: return
	
	var max_freq_amp = bars.reduce(func(m, b): return b if b.size.y > m.size.y else m).size.y

	for i in range(NUM_BARS):
		var freq_start = (i * MAX_FREQUENCY) / NUM_BARS
		var freq_end = ((i+1) * MAX_FREQUENCY) / NUM_BARS
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(freq_start, freq_end).length()

		var bar_max_height = sqrt(magnitude) * 1000

		bars[i].size.y = MIN_Y_HEIGHT + lerp(bars[i].size.y, bar_max_height, 0.2)
		bars[NUM_BARS * 2 - i - 1].size.y = MIN_Y_HEIGHT + lerp(bars[i].size.y, bar_max_height, 0.2)

		var intensity = (magnitude * 1000) / (max_freq_amp * 1000.0) if max_freq_amp > 0 else 0.0
		intensity *= 1000
		intensity = clamp(intensity, 0.0, 1.0)
		bars[i].scale.y = -1
		bars[NUM_BARS * 2 - i - 1].scale.y = -1
	

		var new_color = gradient.sample(intensity)
		bars[i].color = (bars[i].color + new_color) / 2
		bars[NUM_BARS * 2 - i -1].color = (bars[i].color + new_color) / 2
