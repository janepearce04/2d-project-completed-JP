extends CharacterBody2D

signal health_depleted

@export var SPEED = 450.0
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 1.5

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var last_move_direction := Vector2.DOWN
var dash_direction := Vector2.ZERO

var health = 100.0
var traps_hit := {}   # tracks which traps already damaged us, so we don't drain 10/frame

func _physics_process(delta: float) -> void:
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		last_move_direction = direction

	# Tick cooldown down every frame, regardless of what state we're in.
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		velocity = direction * SPEED
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
			_start_dash()

	move_and_slide()

	if velocity.length() > 0.0:
		%PixelSprite.play_walk_animation()
	else:
		%PixelSprite.play_idle_animation()

	# Mobs: continuous damage while overlapping
	for body in %HurtBox.get_overlapping_bodies():
		if body.get_collision_layer_value(2):
			_take_damage(3 * delta)

	# Traps: one-shot damage per entry, not per frame
	for area in %HurtBox.get_overlapping_areas():
		if area.get_collision_layer_value(3) and not traps_hit.has(area):
			traps_hit[area] = true
			_take_damage(15)
			if area.has_method("activate"):
				area.activate()

func _start_dash() -> void:
	%PixelSprite.play_dash_animation()
	is_dashing = true
	dash_direction = last_move_direction
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

func _on_hurt_box_area_exited(area: Area2D) -> void:
	traps_hit.erase(area)   # lets the same trap re-trigger if player leaves and returns

func _take_damage(amount: float) -> void:
	%PixelSprite.play_hurt_animation()
	health -= amount
	%HealthBar.value = health
	if health <= 0.0:
		health_depleted.emit()
