extends Node2D

var score = 0

func _restart():
	get_tree().paused = false
	score = 0
	get_tree().reload_current_scene()

const CHUNK_SIZE := 256.0   # tune this to your world scale
var visited_chunks := {}    # Vector2i -> true

func _get_chunk(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / CHUNK_SIZE), floor(pos.y / CHUNK_SIZE))

func _on_explore_timer_timeout() -> void:
	var chunk = _get_chunk(%Player2.global_position)
	if not visited_chunks.has(chunk):
		visited_chunks[chunk] = true
		for i in randi_range(2, 4):
			spawn_tree()
			
		if randf() < 0.3:   # tune trap frequency however you like
			spawn_trap()

func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.global_position = %PathFollow2D.global_position
	new_mob.died.connect(_on_mob_died)
	add_child(new_mob)

func spawn_tree():
	%TreePath2d.progress_ratio = randf()
	var Tree1 = preload("res://trees/pine_tree.tscn").instantiate()
	var Tree2 = preload("res://trees/pine_tree_2.tscn").instantiate()
	var Tree3 = preload("res://trees/pine_tree_3.tscn").instantiate()
	var Bush = preload("res://trees/bush.tscn").instantiate()
	var Bush2 = preload("res://trees/bush_2.tscn").instantiate()
	
	var folliage_tree = [Tree1, Tree2, Tree3, Bush, Bush2]
	var TreeRand = folliage_tree.pick_random()
	
	TreeRand.global_position = %TreePath2d.global_position
	add_child(TreeRand)

func spawn_trap():
	%TreePath2d.progress_ratio = randf()
	var trap = preload("res://trap.tscn").instantiate()
	trap.global_position = %TreePath2d.global_position
	add_child(trap)

func _on_timer_timeout():
	spawn_mob()

func _on_player_health_depleted():
	%GameOver.show()
	get_tree().paused = true

func _on_player_2_health_depleted() -> void:
	%GameOver.show()
	get_tree().paused = true

func _on_mob_died() -> void:
	%Score.add_point()

func _on_score_score_changed(new_score: int) -> void:
	%Score.text = "Score: %d" % new_score

func _on_button_pressed() -> void:
	_restart()
