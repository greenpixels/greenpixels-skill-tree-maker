extends Button

signal drag_started(name: String)

var _property_name: String = ""
var _mouse_down_pos: Vector2 = Vector2.ZERO
var _mouse_down: bool = false

func setup(prop_name: String) -> void:
	_property_name = prop_name

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_mouse_down = true
			_mouse_down_pos = event.global_position
		else:
			_mouse_down = false

func _input(event: InputEvent) -> void:
	if _mouse_down and event is InputEventMouseMotion:
		if event.global_position.distance_to(_mouse_down_pos) > 5.0:
			_mouse_down = false
			_start_drag()

func _start_drag() -> void:
	var parent := get_parent()
	while parent:
		if parent.has_method("start_drag"):
			parent.start_drag(_property_name)
			return
		parent = parent.get_parent()