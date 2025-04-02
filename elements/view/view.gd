extends GraphEdit

@export var center_point : GraphElement
var skill_node_scene : PackedScene = preload("res://elements/skill_node/skill_node.tscn")
var skill_nodes : Dictionary[String, SkillNode] = {}

func _draw() -> void:
	draw_circle(center_point.get_screen_position(), 2, Color.from_rgba8(255, 255, 255, 80))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_released():
			DragContext.cancel_drag()
			
func _on_add_skill_button_pressed() -> void:
	var skill_node : SkillNode = skill_node_scene.instantiate()
	add_child(skill_node)
	skill_node.position_offset = center_point.position_offset
