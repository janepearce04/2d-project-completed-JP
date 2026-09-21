extends AnimationPlayer

@onready var intro_sprite: Sprite2D = %"BOSS intro"
@onready var move_sprite: Sprite2D = %"BOSS Move"
@onready var idle_sprite: Sprite2D = %"BOSS Idle"
@onready var attack_1sprite: Sprite2D = %"BOSS Attack1"
@onready var attack_2sprite: Sprite2D = %"BOSS Attack2"
@onready var death_sprite: Sprite2D = %"BOSS Death"

var switch_sprites: Array[Sprite2D] = []
var curSprite: Sprite2D

func activate_sprite(sprite: Sprite2D) -> void:
	assert(sprite != null)
	assert(sprite in switch_sprites)
	for s in switch_sprites:
		sprite = curSprite
		s.visible = s == sprite

var facing_left: bool = false

func _ready() -> void:
	switch_sprites = [
		intro_sprite,
		move_sprite,
		attack_1sprite,
		attack_2sprite,
		idle_sprite,
		death_sprite
		]
	for i in switch_sprites.size():
		if switch_sprites[i] == null:
			push_error("Boss animation sprite '%s' is null — check its unique name / node path." % switch_sprites[i])

	pause()

func set_facing(dir_x: float) -> void:
	if dir_x == 0:
		return
	facing_left = dir_x < 0
	curSprite.flip_h = facing_left

func flash_hurt() -> void:
	if curSprite == null:
		return
	curSprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	curSprite.modulate = Color.WHITE

signal attack_animation_finished

func play_idle_animation():
	activate_sprite(idle_sprite)
	play("idle")

func play_walk_animation():
	activate_sprite(move_sprite)
	play("move")

func play_intro_animation():
	activate_sprite(intro_sprite)
	play("intro")
	
func play_attack1_animation():
	activate_sprite(attack_1sprite)
	play("attack 1")
	attack_animation_finished.emit()
	
func play_attack2_animation():
	activate_sprite(attack_2sprite)
	play("attack 2")
	attack_animation_finished.emit()
	
func play_Death_animation():
	activate_sprite(death_sprite)
	play("Death")

func play_hurt_animation():
	flash_hurt()
