extends Node2D

func play_idle_animation():
	%AnimationPlayer.play("idle")

func play_walk_animation():
	%AnimationPlayer.play("run")

func play_dash_animation():
	%AnimationPlayer.play("dash")
