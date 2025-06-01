extends Node3D

@onready var world_generator := $WorldGenerator
@onready var sun := $DirectionalLight3D
@onready var environment := $WorldEnv

@export var cycle_duration := 120.0 # seconds for full day/night cycle

var cycle_time := 0.0
var last_reset_done := false

func _input(event):
	if event.is_action_pressed("regenerate_world"):
		var boat_pos = $"../Boat".global_position
		print("Boat position is" + boat_pos)
		world_generator.generate_world(boat_pos)

func _ready():
	cycle_time = 0.0

	# Setup procedural sky using valid properties
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.2, 0.4, 0.6)
	sky_material.sky_horizon_color = Color(0.8, 0.9, 1.0)
	sky_material.sky_curve = 0.5
	sky_material.sky_energy_multiplier = 1.0
	sky_material.ground_bottom_color = Color(0.1, 0.05, 0.02)
	sky_material.ground_horizon_color = Color(0.4, 0.3, 0.2)
	sky_material.ground_curve = 0.02
	sky_material.ground_energy_multiplier = 1.0
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.15

	# Wrap the material in a Sky resource
	var sky := Sky.new()
	sky.set_material(sky_material)

	# Set up the environment resource
	var env_resource := Environment.new()
	env_resource.sky = sky
	env_resource.background_mode = Environment.BGMode.BG_SKY
	env_resource.ambient_light_color = Color(1, 1, 1)
	env_resource.ambient_light_energy = 1.0
	env_resource.ambient_light_sky_contribution = 1.0

	# Assign to the WorldEnvironment node
	environment.environment = env_resource

func _process(delta):
	cycle_time += delta
	if cycle_time > cycle_duration:
		cycle_time -= cycle_duration
		last_reset_done = false

	# Simulate sun orbit
	var cycle_progress = cycle_time / cycle_duration
	var sun_angle_deg = cycle_progress * 360.0
	sun.rotation_degrees.x = sun_angle_deg

	update_environment(sun_angle_deg)

	# Trigger reset exactly at "midnight" (sun behind the world)
	if not last_reset_done and abs(sun_angle_deg - 180.0) < 1.0:
		world_generator.generate_world()
		last_reset_done = true

func update_environment(angle_deg: float):
	var darkness = abs(180.0 - angle_deg) / 180.0  # 0 = noon, 1 = midnight

	# Dim the sun's light directly
	sun.light_energy = lerp(1.0, 0.05, darkness)

	# Adjust environment settings during night/day cycle
	var env: Environment = environment.environment
	env.ambient_light_energy = lerp(1.0, 0.2, darkness)

	# Adjust sky brightness safely
	var sky_mat = env.sky.get_material() 
	if sky_mat is ProceduralSkyMaterial:
		sky_mat.sky_energy_multiplier = lerp(1.0, 0.2, darkness)
		sky_mat.ground_energy_multiplier = lerp(1.0, 0.2, darkness)

		# Optional: tint the horizon colors for dusk effect
		sky_mat.sky_horizon_color = Color(0.8, 0.9, 1.0).lerp(Color(0.6, 0.3, 0.2), darkness)
		sky_mat.ground_horizon_color = Color(0.4, 0.3, 0.2).lerp(Color(0.1, 0.05, 0.02), darkness)
