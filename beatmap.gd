class_name BeatMap
extends Resource

var bpm: int = 120
var song_stream = load("res://2024-01-17-#RadiateNeon_Cutscene.mp3")

# Include all measures (even empty ones) for clarity
var right_side_timings = {
	1: [1],
	2: [2],
	3: [3],
	4: [4],
	5: [1],
	6: [2],
	7: [3],
	8: [4],
	9: [1],
	10: [2],
	11: [3],
	12: [4],
	13: [1],
	14: [2],
	15: [3],
	16: [4],
}

var left_side_timings = {
	1: [1],
	2: [2],
	3: [3],
	4: [4],
	5: [1],
	6: [2],
	7: [3],
	8: [4],
	9: [1],
	10: [2],
	11: [3],
	12: [4],
	13: [1],
	14: [2],
	15: [3],
	16: [4],
}
