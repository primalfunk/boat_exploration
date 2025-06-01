extends CharacterBody3D

@export var move_speed := 4.0
@export var turn_speed := 1.5
@export var acceleration := 3.0
@export var deceleration := 2.0
@export var max_speed := 8.0

@onready var propeller_particles := $PropellerParticles
@onready var prompt_panel := get_node("../InteractionPrompt/PromptContainer")
@onready var fishing_prompt := get_node("../InteractionPrompt/PromptContainer/FishingPrompt")

var can_interact := false
var current_speed := 0.0
var direction: Vector3 = Vector3.ZERO
var smoothed_wave_y := 0.0

const BOAT_HEIGHT := 4
const PROP_DEPTH_MARGIN := 0.05
const WAVE_MAX_HEIGHT := 0.035
const DECK_LEVEL_RATIO := -0.3

func get_wave_height(x: float, z: float, time: float) -> float:
	var wave_amp_1 = 0.05
	var wave_amp_2 = 0.04
	var wave_freq_1 = 0.9
	var wave_freq_2 = 0.6
	var wave_speed = 1.9
	var t = time * wave_speed
	var wave1 = sin(x * wave_freq_1 + t) * wave_amp_1
	var wave2 = cos(z * wave_freq_2 + t) * wave_amp_2
	return wave1 + wave2

func _ready():
	configure_particles()
	
func update_prompt_visibility(visible: bool):
	var active_text_color = Color(1.0, 0.95, 0.8, 1.0)        # Pale gold
	var inactive_text_color = Color(0.8, 0.75, 0.9, 0.1)      # Gentle lavender-white

	var active_bg_color = Color(0.5, 0.2, 0.6, 0.6)           # Mystical purple
	var inactive_bg_color = Color(0.5, 0.2, 0.6, 0.05)        # Transparent purple tint

	fishing_prompt.modulate = active_text_color if visible else inactive_text_color
	prompt_panel.modulate = active_bg_color if visible else inactive_bg_color

func _physics_process(delta):
	# Update movement input
	var thrusting := Input.is_action_pressed("move_forward")
	var reversing := Input.is_action_pressed("move_backward")

	# Acceleration or deceleration
	if thrusting:
		current_speed += acceleration * delta
	elif reversing:
		current_speed -= acceleration * delta
	else:
		# Apply drag
		if abs(current_speed) > 0.1:
			current_speed -= sign(current_speed) * deceleration * delta
		else:
			current_speed = 0.0

	current_speed = clamp(current_speed, -max_speed * 0.5, max_speed)

	# Show fishing prompt optional styling
	var target_alpha = 1.0 if can_interact else 0.2
	fishing_prompt.modulate.a = lerp(fishing_prompt.modulate.a, target_alpha, delta * 5)

	# Turning (allowed while coasting)
	if Input.is_action_pressed("turn_left"):
		rotate_y(-turn_speed * delta)
	if Input.is_action_pressed("turn_right"):
		rotate_y(turn_speed * delta)
		
	if Input.is_action_just_pressed("interact") and can_interact:
		print("✅ Interacted with collectible!")  # placeholder
		
	# Move in the boat's forward direction
	var forward_dir := transform.basis.z
	self.velocity = forward_dir * current_speed
	move_and_slide()

	# Emit particles only when player is actively applying throttle (not coasting)
	var is_thrusting := Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")
	propeller_particles.emitting = is_thrusting

	if is_thrusting:
		var boat_back_dir := -global_transform.basis.z.normalized()
		var velocity_vector := boat_back_dir
		var speed := velocity.length()
		var jet_strength : float = clamp(speed * 1.5, 1.0, 5.0)
		propeller_particles.process_material.set("gravity", Vector3(0, -0.9, 0))
		propeller_particles.process_material.set("velocity", velocity_vector)
		propeller_particles.lifetime = 3.0
		propeller_particles.emitting = true
		print("World velocity:", velocity_vector * jet_strength)
		print("Emitter position:", propeller_particles.global_transform.origin)
	else:
		propeller_particles.emitting = false

	var t := Time.get_ticks_msec() / 1000.0
	var x := global_position.x
	var z := global_position.z

	# Real wave height from shader function
	var wave_y := get_wave_height(x, z, t)

	# Smooth the wave height slightly for realism
	smoothed_wave_y = lerp(smoothed_wave_y, wave_y, 0.05)

	# Clamp the boat's Y to avoid being submerged
	var desired_clearance := 0.15  # You can tweak this!
	var target_y := wave_y + desired_clearance
	global_position.y = lerp(global_position.y, target_y, 0.05) 
	
func configure_particles():
	if propeller_particles.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = propeller_particles.process_material

		# Duplicate so we don’t accidentally affect a shared resource
		if not mat.resource_local_to_scene:
			mat = mat.duplicate()
			mat.resource_local_to_scene = true
			propeller_particles.process_material = mat

		# Chaotic movement setup
		mat.initial_velocity_min = 0.2
		mat.initial_velocity_max = 1.5
		mat.spread = 3.0
		mat.flatness = 0.3

		mat.angular_velocity_min = -10.0
		mat.angular_velocity_max = 10.0

		mat.scale_min = 0.4
		mat.scale_max = 1.2

		# Fade-out over lifetime
		var alpha_curve := Curve.new()
		alpha_curve.add_point(Vector2(0.0, 1.0))
		alpha_curve.add_point(Vector2(0.7, 0.6))
		alpha_curve.add_point(Vector2(1.0, 0.0))
		var tex := CurveTexture.new()
		tex.curve = alpha_curve
		mat.alpha_curve = tex
