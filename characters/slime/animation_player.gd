extends AnimationPlayer

@onready var run_sprite: Sprite2D = %SkeleBodyWalk
@onready var idle_sprite: Sprite2D = %SkeleBodyIdle
@onready var hurt_sprite: Sprite2D = %SkeleBodyHurt

var switch_sprites: Array[Sprite2D] = []

func _ready() -> void:
	switch_sprites = [
		run_sprite,
		idle_sprite,
		hurt_sprite
		]

func activate_sprite(sprite: Sprite2D) -> void:
	assert(sprite != null)
	assert(sprite in switch_sprites)
	for s in switch_sprites:
		s.visible = s == sprite
		
var facing_left: bool = false

func set_facing(dir_x: float) -> void:
	if dir_x == 0:
		return
	facing_left = dir_x < 0
	for sprite in switch_sprites:
		sprite.flip_h = facing_left
		
func flash_hurt() -> void:
	for sprite in switch_sprites:
		sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	for sprite in switch_sprites:
		sprite.modulate = Color.WHITE
