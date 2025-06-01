extends Node3D

const WORLD_SIZE := 3000
const LAND_COVERAGE := 0.10
const MIN_ISLAND_SIZE := 40
const MAX_ISLAND_SIZE := 60
const ISLAND_HEIGHT := 1.5
const ISLAND_DEPTH := 6.0
const SAFE_RADIUS := 10.0

@onready var boat := $"../Boat"
@onready var water_plane := $"../Ocean"
const IslandScene := preload("res://scenes/Island.tscn")
const CollectiblePoint := preload("res://scenes/CollectiblePoint.tscn")

var land_tiles: Array = []

func _ready():
	randomize()
	generate_world()
	call_deferred("spawn_collectibles")

func generate_world():
	# Clear old land
	for land in land_tiles:
		remove_child(land)
		land.free()
	land_tiles.clear()

	var area = WORLD_SIZE * WORLD_SIZE
	var target_land_area = area * LAND_COVERAGE
	var placed_land_area = 0.0

	while placed_land_area < target_land_area:
		var size = randf_range(MIN_ISLAND_SIZE, MAX_ISLAND_SIZE)
		var x = randf_range(-WORLD_SIZE/2, WORLD_SIZE/2)
		var z = randf_range(-WORLD_SIZE/2, WORLD_SIZE/2)

		# Instantiate reusable Island scene
		var land = IslandScene.instantiate()

		# Get references to parts inside the Island scene
		var mesh_instance := land.get_node("MeshInstance3D")
		var collider := land.get_node("CollisionShape3D")

		# Scale the mesh and collider
		mesh_instance.mesh.size = Vector3(size, ISLAND_HEIGHT + ISLAND_DEPTH, size)
		collider.shape.size = Vector3(size, ISLAND_HEIGHT + ISLAND_DEPTH, size)

		# Apply land material
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.1)
		mesh_instance.material_override = mat

		# Position land in the world
		land.position = Vector3(x, -(ISLAND_DEPTH / 2.0), z)

		# Add to scene and tracking list
		add_child(land)
		land_tiles.append(land)
		print("Appending land:", land.name)
		placed_land_area += size * size

	# Place boat
	place_boat_safely()
	print(land_tiles.size())

func spawn_collectibles():
	for i in 10:
		var pos = get_valid_water_position()
		var collectible = CollectiblePoint.instantiate()
		add_child(collectible)  # ✅ Add it to the tree first
		collectible.global_position = pos + Vector3(0, -1.0, 0)

func place_boat_safely():
	var boat_pos = Vector3.ZERO
	var tries = 0
	var max_tries = 500

	while tries < max_tries:
		# Generate a spawn radius that increases over time (biased toward center)
		var radius = float(tries) / float(max_tries) * (WORLD_SIZE / 2.0)
		var angle = randf() * TAU

		boat_pos.x = cos(angle) * radius
		boat_pos.z = sin(angle) * radius
		boat_pos.y = 0

		var too_close = false
		for land in land_tiles:
			var land_center = land.global_position
			var dist = land_center.distance_to(boat_pos)
			if dist < SAFE_RADIUS + land.get_node("MeshInstance3D").mesh.size.x / 2.0:
				too_close = true
				break

		if not too_close:
			boat.global_position = boat_pos
			# Add guaranteed collectible nearby
			var collectible = CollectiblePoint.instantiate()
			add_child(collectible)  # ✅ Add to tree first
			var offset = Vector3(randf_range(-8, 8), -1.0, randf_range(-8, 8))
			collectible.global_position = boat_pos + offset
			
			return

		tries += 1

	push_error("Couldn't find safe placement for boat!")

func get_valid_water_position() -> Vector3:
	var tries = 0
	var max_tries = 100

	while tries < max_tries:
		var x = randf_range(-WORLD_SIZE / 2, WORLD_SIZE / 2)
		var z = randf_range(-WORLD_SIZE / 2, WORLD_SIZE / 2)
		var pos = Vector3(x, 0, z)

		var too_close = false
		for land in land_tiles:
			var land_center = land.global_position
			var land_radius = land.get_node("MeshInstance3D").mesh.size.x / 2.0
			if land_center.distance_to(pos) < SAFE_RADIUS + land_radius:
				too_close = true
				break

		if not too_close:
			return pos

		tries += 1

	push_error("Couldn't find valid water position for collectible.")
	return Vector3.ZERO
