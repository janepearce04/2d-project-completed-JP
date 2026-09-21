extends Node2D

@export var activation_delay := 1.5
@export var camera_transition_duration := 1.2

# Set this to the arena's play area (roughly screen-sized). Drives both the
# camera lock and the "no props/mobs spawn here" exclusion zone.
@export var arena_bounds : Rect2 = Rect2()

@onready var activation_box: Area2D = %"ACTIVATION BOX"
@onready var boss: Node2D = $BOSS

var _boss_triggered := false


func _ready() -> void:
	arena_bounds.position = Vector2(-300, -7000)
	arena_bounds.size = Vector2(800, 800)
	
	activation_box.body_entered.connect(_on_body_entered)
	activation_box.body_exited.connect(_on_body_exited)

	var game = get_tree().get_first_node_in_group("Game")
	if game:
		game.register_exclusion_zone(arena_bounds)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_lock_camera_to_arena()

	if not _boss_triggered:
		_boss_triggered = true
		var game = get_tree().get_first_node_in_group("Game")
		if game:
			game.pause_mob_spawning()
			game.clear_all_mobs()
		if boss.has_method("activate"):
			boss.activate(activation_delay)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_unlock_camera_to_world()

func _lock_camera_to_arena() -> void:
	var game = get_tree().get_first_node_in_group("Game")
	if game and game.playerCam:
		game.playerCam.transition_to_boundaries(arena_bounds, camera_transition_duration)

func _unlock_camera_to_world() -> void:
	var game = get_tree().get_first_node_in_group("Game")
	if game and game.playerCam:
		game.playerCam.transition_to_boundaries(game.world_rect, camera_transition_duration)
