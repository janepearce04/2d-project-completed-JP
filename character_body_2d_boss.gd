extends CharacterBody2D

signal died
signal defeated  # emitted on boss defeat specifically, in case you want to hook level-unlock logic to just this

# --- Health / defense -------------------------------------------------------
@export var max_health := 75.0
var health := max_health

@export var starting_defense := 4.0
var defense := starting_defense

# --- Movement / "dance" behavior --------------------------------------------
@export var move_speed := 200.0
@export var arena_center := Vector2.ZERO
@export var arena_radius := 400.0
@export var decision_interval_min := 0.9
@export var decision_interval_max := 2.1
@export var chase_chance := 0.35

var _target_point := Vector2.ZERO
var _decision_timer := 0.0

# --- Attacks -----------------------------------------------------------------
@export var slam_range := 140.0
@export var dagger_min_range := 140.0
@export var dagger_max_range := 500.0
@export var slam_cooldown := 2.5
@export var dagger_cooldown := 3.0
@export var dagger_count := 3
@export var dagger_spread_degrees := 20.0
@export var slam_damage := 25.0
@export var dagger_damage := 10.0

# How many seconds into each attack animation the damage/projectiles should
# actually land. Tune these against your animation's real timing.
@export var slam_hit_delay := 0.4
@export var dagger_release_delay := 0.5

var _slam_cooldown_timer := 0.0
var _dagger_cooldown_timer := 0.0
var _is_attacking := false

# The boss does nothing at all — no facing, movement, or attacks — until
# activate() is called by the arena trigger.
var is_active := false

@onready var player: Node2D = get_node("/root/Game/Player2")  # adjust to match your scene tree
@onready var visuals: Node2D = %Visuals
@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var slam_hitbox: Area2D = %SlamHitbox
@onready var dagger_spawn: Marker2D = %DaggerSpawn


func _ready() -> void:
	add_to_group("boss")
	if arena_center == Vector2.ZERO:
		arena_center = global_position
	_pick_new_target()

	# The AnimationPlayer's built-in animation_finished signal fires whenever
	# ANY animation on it completes — use that instead of emitting a custom
	# signal from inside play_attack1/2_animation() (which fired instantly,
	# at the start of the animation, not the end).
	anim.animation_finished.connect(_on_animation_finished)


# Called once by the arena's activation trigger. Plays the intro animation,
# waits `delay` seconds so the player can actually watch it, then lets the
# boss start acting. Safe to call more than once — later calls are ignored.
func activate(delay: float = 0.0) -> void:
	if is_active:
		return
	# Defensive: in case the intro animation's last keyframe leaves the
	# sprite layer hidden (a Visibility/Modulate track on Visuals), force it
	# back to a known-good state both before and after the intro plays.
	visuals.visible = true
	visuals.modulate = Color.WHITE
	anim.play_intro_animation()
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	visuals.visible = true
	visuals.modulate = Color.WHITE
	is_active = true


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	_face_player()

	if _slam_cooldown_timer > 0.0:
		_slam_cooldown_timer -= delta
	if _dagger_cooldown_timer > 0.0:
		_dagger_cooldown_timer -= delta

	if not _is_attacking:
		_try_attack()

	if not _is_attacking:
		_update_movement(delta)
	else:
		velocity = Vector2.ZERO

	if not _is_attacking:
		if velocity.length() > 0.0:
			anim.play_walk_animation()
		else:
			anim.play_idle_animation()

	move_and_slide()


func _face_player() -> void:
	if not is_instance_valid(player):
		return
	var facing_right := global_position.direction_to(player.global_position).x >= 0.0
	visuals.scale.x = abs(visuals.scale.x) * (1.0 if facing_right else -1.0)


# --- Movement ----------------------------------------------------------------

func _update_movement(_delta: float) -> void:
	_decision_timer -= _delta
	if _decision_timer <= 0.0 or global_position.distance_to(_target_point) < 16.0:
		_pick_new_target()

	velocity = global_position.direction_to(_target_point) * move_speed


func _pick_new_target() -> void:
	_decision_timer = randf_range(decision_interval_min, decision_interval_max)

	if is_instance_valid(player) and randf() < chase_chance:
		_target_point = player.global_position
	else:
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(0.0, arena_radius)
		_target_point = arena_center + Vector2(cos(angle), sin(angle)) * dist


# --- Attack selection ----------------------------------------------------------

func _try_attack() -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)

	if dist <= slam_range and _slam_cooldown_timer <= 0.0:
		_start_slam()
	elif dist >= dagger_min_range and dist <= dagger_max_range and _dagger_cooldown_timer <= 0.0:
		_start_dagger_volley()


func _start_slam() -> void:
	_is_attacking = true
	_slam_cooldown_timer = slam_cooldown
	velocity = Vector2.ZERO
	anim.play_attack1_animation()
	await get_tree().create_timer(slam_hit_delay).timeout
	if is_instance_valid(self):
		_apply_slam_damage()


func _apply_slam_damage() -> void:
	for body in slam_hitbox.get_overlapping_bodies():
		if body != self and body.has_method("_take_damage"):
			body._take_damage(slam_damage)


func _start_dagger_volley() -> void:
	_is_attacking = true
	_dagger_cooldown_timer = dagger_cooldown
	velocity = Vector2.ZERO
	anim.play_attack2_animation()
	await get_tree().create_timer(dagger_release_delay).timeout
	if is_instance_valid(self):
		_fire_daggers()


func _fire_daggers() -> void:
	if not is_instance_valid(player):
		return
	var base_dir := global_position.direction_to(player.global_position)
	var mid := (dagger_count - 1) / 2.0
	for i in dagger_count:
		var offset_deg := (i - mid) * dagger_spread_degrees
		var dir := base_dir.rotated(deg_to_rad(offset_deg))
		var dagger = preload("res://boss_dagger.tscn").instantiate()
		get_parent().add_child(dagger)
		dagger.global_position = dagger_spawn.global_position
		dagger.direction = dir
		dagger.damage = dagger_damage


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack 1" or anim_name == "attack 2":
		_is_attacking = false


# --- Health / defense ---------------------------------------------------------

func take_damage(amount := 1.0) -> void:
	if health <= 0.0:
		return
	health -= amount / defense
	anim.play_hurt_animation()
	if health <= 0.0:
		_die()


# Called by Chest.gd via call_group("boss", "on_chest_collected") — name
# must match exactly (no leading underscore) since it's called externally.
func on_chest_collected() -> void:
	defense = max(1.0, defense - 1.0)

func _die() -> void:
	anim.play_Death_animation()
	died.emit()
	defeated.emit()
	# Give the death animation a moment to actually play before removing
	# the boss — queue_free() right away would cut it off at frame 0.
	await get_tree().create_timer(1.0).timeout
	queue_free()
