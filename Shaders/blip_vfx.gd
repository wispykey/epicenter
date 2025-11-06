extends ColorRect

func _ready() -> void:
    $Timer.timeout.connect(_on_timer_timeout)
    material = material.duplicate()


func _process(delta: float) -> void:
    material.set_shader_parameter("t", material.get_shader_parameter("t") + delta)

func _on_timer_timeout():
    queue_free()