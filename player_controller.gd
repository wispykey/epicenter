extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hit_ring1_right"):
		print("HIT Ring1 RIGHT")
