extends StaticBody3D

@export var island_id: int = 0
@export var is_discovered := false

func mark_as_discovered():
	is_discovered = true
	# Add visual cue or trigger logic later
