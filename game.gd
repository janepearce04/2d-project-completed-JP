extends Node2D

var score = 0
@onready var player: CharacterBody2D = $"Player2"
@onready var tile_map: TileMapLayer = $"TileMap-Walls"
@onready var playerCam: Camera2D = $Player2/Camera2D

@export var world_half_size := Vector2(10000, 10000)

@export var wall_avoid_margin := 128.0

var world_rect: Rect2
var interior_rect: Rect2 

const WALL_SOURCE_ID := 7

var WALL_PATTERN: Array[Vector2i] = [
	Vector2i(3,11),
	Vector2i(4,11),
	Vector2i(5,11),
	Vector2i(6,11),
	Vector2i(7,11),
	Vector2i(8,11),
	Vector2i(9,11),
	Vector2i(10,11)
]

# The cap/coping tile that sits in the row just outside the body row.
var WALL_CAP_ATLAS : Array[Vector2i] = [
	Vector2i(2, 10),
	Vector2i(3, 10),
	Vector2i(4, 10),
	Vector2i(5, 10),
	Vector2i(6, 10),
	Vector2i(7, 10),
	Vector2i(8, 10),
	Vector2i(9, 10),
	Vector2i(10, 10),
	Vector2i(11, 10)
]

var WALL_SIDE_ATLAS : Array[Vector2i] = [
	Vector2i(2, 2),
	Vector2i(2, 3),
	Vector2i(2, 4),
	Vector2i(2, 5),
	Vector2i(2, 6),
	Vector2i(2, 7),
	Vector2i(2, 8),
	Vector2i(2, 9)
]

func _enter_tree() -> void:
	add_to_group("Game")

var _exclusion_zones: Array[Rect2] = []

func register_exclusion_zone(rect: Rect2) -> void:
	_exclusion_zones.append(rect)

@onready var mob_spawn_timer: Timer = $Timer 

func pause_mob_spawning() -> void:
	mob_spawn_timer.stop()

func resume_mob_spawning() -> void:
	mob_spawn_timer.start()

func clear_all_mobs() -> void:
	for mob in get_tree().get_nodes_in_group("mob"):
		mob.queue_free()

func _ready() -> void:
	$"Player2".add_to_group("player")
	_generate_world_walls()
	playerCam.set_camera_boundaries(world_rect)
	_populate_static_props()

func _generate_world_walls() -> void:
	var start_pos: Vector2 = player.global_position

	world_rect = Rect2(start_pos - world_half_size, world_half_size * 2.0)

	var top_left_cell: Vector2i = tile_map.local_to_map(tile_map.to_local(world_rect.position))
	var bottom_right_cell: Vector2i = tile_map.local_to_map(tile_map.to_local(world_rect.position + world_rect.size))

	var variants := WALL_PATTERN.size()

	for x in range(top_left_cell.x - 1, bottom_right_cell.x + 1):
		var variant := WALL_PATTERN[posmod(x, variants)]

		# Top wall: body sits on the top edge row, cap sits one row above it.
		tile_map.set_cell(Vector2i(x, top_left_cell.y), WALL_SOURCE_ID, variant)
		tile_map.set_cell(Vector2i(x, top_left_cell.y-1), WALL_SOURCE_ID, WALL_CAP_ATLAS[randi_range(0, 9)])

		# Bottom wall: cap sits one row below it.
		tile_map.set_cell(
			Vector2i(x, bottom_right_cell.y),
			WALL_SOURCE_ID,
			variant
		)
		tile_map.set_cell(
			Vector2i(x, bottom_right_cell.y -7),
			WALL_SOURCE_ID,
			WALL_CAP_ATLAS[randi_range(0, 9)]
		)

	var side_variants := WALL_SIDE_ATLAS.size()
	for y in range(top_left_cell.y, bottom_right_cell.y):
		var variant := WALL_SIDE_ATLAS[posmod(y, side_variants)]

		tile_map.set_cell(
			Vector2i(top_left_cell.x, y),
			WALL_SOURCE_ID,
			variant
		)

		tile_map.set_cell(
			Vector2i(top_left_cell.x-1, y),
			WALL_SOURCE_ID,
			variant,
			TileSetAtlasSource.TRANSFORM_FLIP_H
		)
		
		tile_map.set_cell(
			Vector2i(bottom_right_cell.x, y),
			WALL_SOURCE_ID,
			variant,
			TileSetAtlasSource.TRANSFORM_FLIP_H
		)

		tile_map.set_cell(
			Vector2i(bottom_right_cell.x+1, y),
			WALL_SOURCE_ID,
			variant
		)

	interior_rect = world_rect.grow(-wall_avoid_margin)

# ---------------------------------------------------------------------------
# One-time world population (replaces the old chunk-exploration spawner)
# ---------------------------------------------------------------------------

@export var initial_tree_count := 1500
@export var initial_trap_count := 100
@export var min_prop_spacing := 256.0   # minimum distance kept between props

var _placed_prop_positions: Array[Vector2] = []

func _random_interior_point() -> Vector2:
	return Vector2(
		randf_range(interior_rect.position.x, interior_rect.position.x + interior_rect.size.x),
		randf_range(interior_rect.position.y, interior_rect.position.y + interior_rect.size.y)
	)

# Placeholder for later: once you add a floor TileMapLayer, check the tile
# under `pos` here and return false for tiles props shouldn't sit on.
func _is_valid_prop_position(pos: Vector2) -> bool:
	for zone in _exclusion_zones:
		if zone.has_point(pos):
			return false
	for existing in _placed_prop_positions:
		if existing.distance_to(pos) < min_prop_spacing:
			return false
	return true

func _find_spawn_point(max_attempts := 20) -> Vector2:
	for i in max_attempts:
		var candidate = _random_interior_point()
		if _is_valid_prop_position(candidate):
			return candidate
	return _random_interior_point()  # give up on spacing/exclusion rather than stall forever

func _populate_static_props() -> void:
	for i in initial_tree_count:
		var pos = _find_spawn_point()
		_placed_prop_positions.append(pos)
		_spawn_tree_at(pos)

	for i in initial_trap_count:
		var pos = _find_spawn_point()
		_placed_prop_positions.append(pos)
		_spawn_trap_at(pos)

func _spawn_tree_at(pos: Vector2) -> void:
	var Tree1 = preload("res://trees/pine_tree.tscn").instantiate()
	var Tree2 = preload("res://trees/pine_tree_2.tscn").instantiate()
	var Tree3 = preload("res://trees/pine_tree_3.tscn").instantiate()
	var Bush = preload("res://trees/bush.tscn").instantiate()
	var Bush2 = preload("res://trees/bush_2.tscn").instantiate()

	var folliage_tree = [Tree1, Tree2, Tree3, Bush, Bush2]
	var TreeRand = folliage_tree.pick_random()
	TreeRand.global_position = pos
	add_child(TreeRand)

func _spawn_trap_at(pos: Vector2) -> void:
	var trap = preload("res://trap.tscn").instantiate()
	trap.global_position = pos
	add_child(trap)

#func _on_explore_timer_timeout() -> void:
	#for i in randi_range(1, 2):
		#var pos = _find_spawn_point()
		#_placed_prop_positions.append(pos)
		#_spawn_tree_at(pos)
	#if randf() < 0.3:
		#var pos = _find_spawn_point()
		#_placed_prop_positions.append(pos)
		#_spawn_trap_at(pos)

func _clamp_to_world(pos: Vector2) -> Vector2:
	if world_rect.size <= Vector2.ZERO:
		return pos
	return Vector2(
		clamp(pos.x, interior_rect.position.x, interior_rect.position.x + interior_rect.size.x),
		clamp(pos.y, interior_rect.position.y, interior_rect.position.y + interior_rect.size.y)
	)

func spawn_mob():
	var pos = _find_spawn_point()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.global_position = pos
	new_mob.died.connect(_on_mob_died)
	add_child(new_mob)

func _restart():
	get_tree().paused = false
	score = 0
	get_tree().reload_current_scene()

func _on_timer_timeout():
	spawn_mob()

func _on_player_2_health_depleted() -> void:
	%GameOver.show()
	get_tree().paused = true

func _on_mob_died() -> void:
	%Score.add_point()

func _on_boss_died() -> void:
	%Score.add_point(100)
	_unlock_next_level()

func _unlock_next_level() -> void:
	# Placeholder until you have a real level transition / gateway object.
	# Swap this out for e.g. changing scene to the next level, or unlocking
	# a door node in the current one.
	%YouWinScreen.show()
	get_tree().paused = true

func _on_score_score_changed(new_score: int) -> void:
	%Score.text = "Score: %d" % new_score

func _on_button_pressed() -> void:
	_restart()

func _on_keys_keys_changed(new_score: int) -> void:
	%Keys.text = "Keys: %d" % new_score
