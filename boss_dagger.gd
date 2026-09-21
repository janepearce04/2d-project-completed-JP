extends Area2D

@export var speed := 600.0
@export var damage := 10.0

@onready var screen_notifier: Node = %VisibleOnScreenNotifier2D

var direction := Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if screen_notifier:
		screen_notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("_take_damage"):
		body._take_damage(damage)
	queue_free()
 
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
