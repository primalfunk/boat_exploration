extends CharacterBody3D

@export var move_speed: float = 2.5
@export var turn_speed: float = 1.2
@export var acceleration: float = 2.0
@export var deceleration: float = 1.5
@export var max_speed: float = 5.0
@export var can_interact: bool = false
@onready var propeller_particles: GPUParticles3D = $PropellerParticles
@onready var prompt_panel := get_node("../InteractionPrompt/PromptContainer")
@onready var fishing_prompt := get_node("../InteractionPrompt/PromptContainer/FishingPrompt")

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var anim_state_machine = animation_tree["parameters/playback"]

var previous_yaw: float = 0.0
var current_speed: float = 0.0
var smoothed_wave_y: float = 0.0

func _ready():
	animation_tree.active = true
	var state_machine = animation_tree.get("parameters/playback")
	state_machine.travel("Idle")
	previous_yaw = rotation.y

func update_prompt_visibility(visible: bool):
	var active_text_color = Color(1.0, 0.95, 0.8, 1.0)
	var inactive_text_color = Color(0.8, 0.75, 0.9, 0.1)
	var active_bg_color = Color(0.5, 0.2, 0.6, 0.6)
	var inactive_bg_color = Color(0.5, 0.2, 0.6, 0.05)
	fishing_prompt.modulate = active_text_color if visible else inactive_text_color
	prompt_panel.modulate = active_bg_color if visible else inactive_bg_color

func get_wave_height(x: float, z: float, time: float) -> float:
	var wave1 := sin(x * 0.9 + time * 1.9) * 0.03
	var wave2 := cos(z * 0.6 + time * 1.9) * 0.02
	return wave1 + wave2

func get_wave_height_and_slope(x: float, z: float, time: float) -> Dictionary:
	var height := get_wave_height(x, z, time)

	# Estimate gradient of the wave to determine slope
	var dx := 0.05
	var dz := 0.05
	var d_wave_dx := (get_wave_height(x + dx, z, time) - get_wave_height(x - dx, z, time)) / (2.0 * dx)
	var d_wave_dz := (get_wave_height(x, z + dz, time) - get_wave_height(x, z - dz, time)) / (2.0 * dz)
	var slope := sqrt(d_wave_dx * d_wave_dx + d_wave_dz * d_wave_dz)

	return {
		"height": height,
		"slope": slope
	}

func _physics_process(delta: float) -> void:
	# -- Movement Input --
	var is_propelling := false
	if Input.is_action_pressed("move_forward"):
		current_speed += acceleration * delta
		is_propelling = true
	elif Input.is_action_pressed("move_backward"):
		current_speed -= acceleration * delta
		is_propelling = true
	else:
		current_speed = move_toward(current_speed, 0.0, deceleration * delta)

	current_speed = clamp(current_speed, -max_speed * 0.5, max_speed)

	# -- Turning Input --
	if Input.is_action_pressed("turn_left"):
		rotate_y(-turn_speed * delta)
	elif Input.is_action_pressed("turn_right"):
		rotate_y(turn_speed * delta)

	# -- Apply Movement --
	var forward_dir := -transform.basis.x
	velocity = forward_dir * current_speed
	move_and_slide()
	
		# -- Toggle Propeller Particles --
	propeller_particles.emitting = is_propelling
	
	# -- Wave Height & Buoyancy Tilt Handling --
	var time := Time.get_ticks_msec() / 1000.0

	# Look slightly ahead to anticipate wave peaks
	var lookahead := -transform.basis.x * 0.3
	var sample_x := global_position.x + lookahead.x
	var sample_z := global_position.z + lookahead.z

	var wave_data: Dictionary = get_wave_height_and_slope(sample_x, sample_z, time)
	var wave_y: float = wave_data["height"]
	var slope: float = wave_data["slope"]

	# Clearance based on slope + fixed minimum buffer
	var min_clearance := 0.2
	var clearance: float = min_clearance + clamp(slope * 0.5, 0.0, 0.1)  # smoother scaling
	var target_y := wave_y + clearance
	var current_y := global_position.y

	# More stable lerp speed logic (fall fast, rise slow)
	var going_down := target_y < current_y
	var lerp_speed := 0.2 if going_down else 0.08

	# Apply vertical smoothing
	global_position.y = lerp(current_y, target_y, lerp_speed)

	# ---- TILTING BASED ON WAVE SLOPE ----
	var dx := 0.3
	var dz := 0.3
	var center := get_wave_height(global_position.x, global_position.z, time)
	var ahead := get_wave_height(global_position.x + dx, global_position.z, time)
	var side := get_wave_height(global_position.x, global_position.z + dz, time)

	# Calculate surface normal
	var normal := Vector3(-ahead + center, 0.3, -side + center).normalized()

	# Use the boat's current forward direction
	var forward := -transform.basis.x.normalized()

	# Build a stable basis from forward and surface normal (as up)
	var right := forward.cross(normal).normalized()
	var adjusted_forward := normal.cross(right).normalized()
	var tilt_basis := Basis(right, normal, adjusted_forward)

	# Preserve yaw by setting only the tilt (x and z)
	var current_euler := rotation
	var target_euler := tilt_basis.get_euler()
	rotation.x = lerp_angle(current_euler.x, target_euler.x, 0.1)
	rotation.z = lerp_angle(current_euler.z, target_euler.z, 0.1)
	
	var current_yaw := rotation.y
	var turning_velocity := current_yaw - previous_yaw
	previous_yaw = current_yaw
	
	# -- Animation Logic --
	var is_turning_left := Input.is_action_pressed("turn_right")
	var is_turning_right := Input.is_action_pressed("turn_left")

	if current_speed > 0.1:
		animation_tree["parameters/playback"].travel("Forward")
	elif current_speed < -0.1:
		animation_tree["parameters/playback"].travel("Reverse")
	elif is_turning_left:
		animation_tree["parameters/playback"].travel("Left")
	elif is_turning_right:
		animation_tree["parameters/playback"].travel("Right")
	else:
		animation_tree["parameters/playback"].travel("Idle")



func play_anim(name: String) -> void:
	if anim_state_machine.get_current_node() != name:
		anim_state_machine.travel(name)
