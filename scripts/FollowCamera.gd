extends Camera3D

@export var target: Node3D
@export var distance := 9.0
@export var height := 3.0
@export var orbit_speed := 60.0

var yaw := 0.0
var pitch := -10.0

func _process(delta):
	if target == null:
		return

	if not (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		var boat_yaw = target.global_transform.basis.get_euler().y
		yaw = lerp_angle(yaw, rad_to_deg(boat_yaw), delta * 5.0)
	else:
		if Input.is_action_pressed("ui_left"):
			yaw += orbit_speed * delta
		if Input.is_action_pressed("ui_right"):
			yaw -= orbit_speed * delta

	# Handle keyboard input
	if Input.is_action_pressed("ui_left"):
		yaw += orbit_speed * delta
	if Input.is_action_pressed("ui_right"):
		yaw -= orbit_speed * delta
		
	var target_pitch = pitch

	if Input.is_action_pressed("cam_pitch_up"):
		target_pitch -= 120 * delta
	if Input.is_action_pressed("cam_pitch_down"):
		target_pitch += 120 * delta

	pitch = clamp(lerp(pitch, target_pitch, 5 * delta), -80, -5)
	# Convert angles to radians
	var yaw_rad = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)

	# Convert yaw and pitch to a 3D directional vector
	var direction = Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	)

	var offset = -direction * distance

	# Set camera position and orientation
	global_position = target.global_transform.origin + Vector3(0, height, 0) + offset
	look_at(target.global_transform.origin + Vector3(0, height, 0), Vector3.UP)
