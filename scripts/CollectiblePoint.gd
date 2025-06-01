extends Node3D

@onready var detection_zone := $DetectionZone
@export var rotation_speed := 30.0

func _ready():
	if detection_zone:
		detection_zone.body_entered.connect(_on_body_entered)
		detection_zone.body_exited.connect(_on_body_exited)

func _process(delta):
	rotate_y(deg_to_rad(rotation_speed * delta))

func _on_body_entered(body):
	if body.name == "Boat":
		body.can_interact = true
		body.update_prompt_visibility(true)

func _on_body_exited(body):
	if body.name == "Boat":
		body.can_interact = false
		body.update_prompt_visibility(false)
