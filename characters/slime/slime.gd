extends Node2D


func play_walk():
	%AnimationPlayer.activate_sprite($SkeleBodyWalk)
	%AnimationPlayer.play("walk")

func play_hurt():
	%AnimationPlayer.flash_hurt()

func play_idle():
	%AnimationPlayer.activate_sprite($SkeleBodyIdle)
	%AnimationPlayer.play("idle")
