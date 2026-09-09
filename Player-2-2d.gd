extends CharacterBody2D

signal health_depleted

var health = 100.0
var traps_hit := {}   # tracks which traps already damaged us, so we don't drain 10/frame

func _physics_process(delta):
	const SPEED = 650.0
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	
	if velocity.length() > 0.0:
		%PixelSprite.play_walk_animation()
	else:
		%PixelSprite.play_idle_animation()
	
	# Mobs: continuous damage while overlapping
	for body in %HurtBox.get_overlapping_bodies():
		if body.get_collision_layer_value(2):
			_take_damage(6 * delta)

	# Traps: one-shot damage per entry, not per frame
	for area in %HurtBox.get_overlapping_areas():
		if area.get_collision_layer_value(3) and not traps_hit.has(area):
			traps_hit[area] = true
			_take_damage(10)
			if area.has_method("activate"):
				area.activate()

func _on_hurt_box_area_exited(area: Area2D) -> void:
	traps_hit.erase(area)   # lets the same trap re-trigger if player leaves and returns

func _take_damage(amount: float) -> void:
	health -= amount
	%HealthBar.value = health
	if health <= 0.0:
		health_depleted.emit()
