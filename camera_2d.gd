extends Camera2D

const halftilesize = 32
const multiplier = 2

func set_camera_boundaries(rect: Rect2) -> void:
	limit_left = int(rect.position.x - multiplier*halftilesize)
	limit_top = int(rect.position.y - 2*multiplier*halftilesize)
	limit_right = int(rect.position.x + rect.size.x + multiplier*halftilesize)
	limit_bottom = int(rect.position.y + rect.size.y + multiplier*halftilesize)

var _limit_tween: Tween

# Smoothly interpolates the camera's limit rectangle to `rect` over `duration`
# seconds instead of snapping instantly like set_camera_boundaries(). Combined
# with Camera2D's own position smoothing, this gives a soft transition when
# entering/exiting a locked-off area like a boss arena.
func transition_to_boundaries(rect: Rect2, duration: float = 1.0) -> void:
	var target_left := int(rect.position.x - multiplier * halftilesize)
	var target_top := int(rect.position.y + 2 * multiplier * halftilesize)
	var target_right := int(rect.position.x + rect.size.x + multiplier * halftilesize)
	var target_bottom := int(rect.position.y + rect.size.y + multiplier * halftilesize)

	if _limit_tween:
		_limit_tween.kill()
	_limit_tween = create_tween()
	_limit_tween.set_parallel(true)
	_limit_tween.tween_method(func(v): limit_left = int(v), float(limit_left), float(target_left), duration)
	_limit_tween.tween_method(func(v): limit_top = int(v), float(limit_top), float(target_top), duration)
	_limit_tween.tween_method(func(v): limit_right = int(v), float(limit_right), float(target_right), duration)
	_limit_tween.tween_method(func(v): limit_bottom = int(v), float(limit_bottom), float(target_bottom), duration)
