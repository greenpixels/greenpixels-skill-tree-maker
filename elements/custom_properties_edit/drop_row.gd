extends VBoxContainer

var _dragging: bool = false
var _drag_name: String = ""
var _hovered_index: int = -1

func start_drag(prop_name: String) -> void:
	_dragging = true
	_drag_name = prop_name

func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		var local_pos := get_local_mouse_position()
		_hovered_index = _get_drop_index(local_pos)
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			_finish_drag()

func _finish_drag() -> void:
	_dragging = false
	var target_index := _hovered_index
	_hovered_index = -1
	queue_redraw()
	if _drag_name.is_empty():
		return
	var keys := CustomPropertyContext.get_custom_properties().keys()
	var drag_index := keys.find(_drag_name)
	if drag_index == -1:
		_drag_name = ""
		return
	if target_index < 0 or target_index > keys.size():
		_drag_name = ""
		return
	if drag_index == target_index or drag_index == target_index - 1:
		_drag_name = ""
		return
	if drag_index < target_index:
		target_index -= 1
	target_index = clampi(target_index, 0, keys.size() - 1)
	CustomPropertyContext.move_custom_property(_drag_name, target_index)
	_drag_name = ""

func _get_drop_index(at_pos: Vector2) -> int:
	for i in get_child_count():
		var child := get_child(i)
		if not child is Control:
			continue
		if at_pos.y < child.position.y + child.size.y / 2.0:
			return i
	return get_child_count()

func _draw() -> void:
	if _hovered_index < 0 or not _dragging:
		return
	var y: float = 0.0
	var child_count := get_child_count()
	if _hovered_index < child_count:
		var child := get_child(_hovered_index) as Control
		y = child.position.y
	elif child_count > 0:
		var child := get_child(child_count - 1) as Control
		y = child.position.y + child.size.y
	else:
		return
	y = clampf(y, 1, size.y - 1)
	draw_rect(Rect2(0, y - 1, size.x, 2), Color(0.4, 0.6, 1, 0.9))