extends Area2D
 
@export var chest_id := 0
var _opened := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
 
func _on_body_entered(body: Node2D) -> void:
	if _opened:
		return
	if body.is_in_group("player"):
		_open()
 
func _open() -> void:
	_opened = true
	%AnimationPlayer.play("open")
	get_tree().call_group("boss", "on_chest_collected")
	queue_free()
