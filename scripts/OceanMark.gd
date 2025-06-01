extends MeshInstance3D

var pulse_speed := 2.0
var base_scale := Vector3.ONE
var pulse_amount := 0.1

func _process(delta):
	var scale_factor = 1.0 + sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) * pulse_amount
	scale = base_scale * scale_factor
