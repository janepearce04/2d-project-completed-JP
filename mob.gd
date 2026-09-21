extends CharacterBody2D

signal died

var speed = randf_range(200, 300)
var health = 3

@onready var player = get_node("/root/Game/Player2")

func _ready():
	add_to_group("mob")
	%Slime.play_walk()

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	
	if direction.x != 0:
		$'Slime/AnimationPlayer'.set_facing(direction.x)

func take_damage():
	%Slime.play_hurt()
	health -= 1

	if health == 0:
		var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = smoke_scene.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		died.emit()
		queue_free()
