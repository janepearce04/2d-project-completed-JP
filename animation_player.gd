extends AnimationPlayer

@onready var sprite: Sprite2D = $"../16x16AllAnimationsSheet"

var facing_left: bool = false

func set_facing(dir_x: float) -> void:
	if dir_x == 0:
		return
	facing_left = dir_x < 0
	sprite.flip_h = facing_left

func flash_hurt() -> void:
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
