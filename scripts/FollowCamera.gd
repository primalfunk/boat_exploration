extends Camera3D

@export var target: Node3D
@export var distance := 9.0
@export var height := 3.0
@export var orbit_speed := 0.3
@export var zoom_speed := 2.0
@export var min_distance := 3.0
@export var max_distance := 15.0
@export var target_offset := Vector3(0, 0.5, 0) 

var yaw := 0.0
var pitch := -15.0
var rotating := false
var last_mouse_pos := Vector2.ZERO

func _unhandled_input(event):
	# Start rotating on left mouse press
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed
			last_mouse_pos = event.position

		# Zoom with scroll wheel
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(min_distance, distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(max_distance, distance + zoom_speed)

	elif event is InputEventMouseMotion and rotating:
		var delta = event.relative
		yaw -= delta.x * orbit_speed
		pitch -= delta.y * orbit_speed
		pitch = clamp(pitch, -80, -5)

func _process(delta):
	if target == null:
		return

	var yaw_rad = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)

	var direction = Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	)

	var offset = -direction * distance
	var target_pos = target.global_transform.origin + target_offset

	global_position = target_pos + offset
	look_at(target_pos, Vector3.UP)
