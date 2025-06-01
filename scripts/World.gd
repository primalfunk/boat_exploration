extends Node3D

@onready var world_generator := $WorldGenerator

func _input(event):
	if event.is_action_pressed("regenerate_world"):
		world_generator.generate_world()
