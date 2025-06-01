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

const BOAT_HEIGHT := 2.5
const PROP_DEPTH_MARGIN := 0.05
const WAVE_MAX_HEIGHT := 0.06

const DECK_LEVEL_RATIO := -0.4

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
		if propeller_particles.process_material.resource_local_to_scene == false:
			propeller_particles.process_material = propeller_particles.process_material.duplicate()
			propeller_particles.process_material.resource_local_to_scene = true
		propeller_particles.process_material.set("gravity", Vector3(0, -1.5, 0))
		propeller_particles.process_material.set("velocity", velocity_vector)
		propeller_particles.lifetime = 3.0
		propeller_particles.emitting = true
		print("World velocity:", velocity_vector * jet_strength)
		print("Emitter position:", propeller_particles.global_transform.origin)
	else:
		propeller_particles.emitting = false

	# Calculate wave height
	var t := Time.get_ticks_msec() / 1000.0
	var x := global_position.x
	var z := global_position.z

	var wave_y := sin(x * 0.5 + t * 2.0) * 0.07
	wave_y += cos(z * 0.6 + t * 2.0) * 0.07

	smoothed_wave_y = lerp(smoothed_wave_y, wave_y, 0.05)

	var lower_deck_target_y := smoothed_wave_y - (BOAT_HEIGHT * DECK_LEVEL_RATIO)
	var propeller_clearance_y := smoothed_wave_y - PROP_DEPTH_MARGIN

	global_position.y = min(lower_deck_target_y, propeller_clearance_y)
