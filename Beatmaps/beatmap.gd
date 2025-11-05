class_name BeatMap
extends Resource

@export var bpm: int = 120
@export var song_stream: AudioStream
@export var is_symmetric: bool = true
@export var is_looping: bool = true

# Include all measures (even empty ones) for clarity
@export var right_side_timings = {}
@export var left_side_timings = {}
