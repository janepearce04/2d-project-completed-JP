extends Node

signal keys_changed(new_score: int)

var keys: int = 0

func add_point(amount: int = 1) -> void:
	keys += amount
	keys_changed.emit(keys)

func reset() -> void:
	keys = 0
	keys_changed.emit(keys)
