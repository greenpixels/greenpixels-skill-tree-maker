extends GraphEdit
class_name View


@export var center_point: GraphElement
const skill_node_scene: PackedScene = preload("res://elements/skill_node/skill_node.tscn")
var skill_nodes: Dictionary[String, SkillNode] = {}

static var current_graph_view : View

func _ready() -> void:
	View.current_graph_view = self

func _draw() -> void:
	draw_circle(center_point.get_screen_position(), 2, Color.from_rgba8(255, 255, 255, 80))

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		_cancel_drag_operation_on_empty.call_deferred()
	
			
func _cancel_drag_operation_on_empty():
	if not DragContext.current_from_connector: return
	DragContext.cancel_connection_drag()
			
func _on_add_skill_button_pressed() -> void:
	var skill_node: SkillNode = skill_node_scene.instantiate()
	add_child(skill_node)

func clear_all():
	for skill_node in SkillNode.skill_node_register.values() as Array[SkillNode]:
		skill_node.delete()
	SkillNode.skill_node_register = {}
	ConnectionEntry.connection_register = {}

func _on_clear_button_pressed() -> void:
	clear_all()
