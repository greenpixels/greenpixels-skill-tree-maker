extends GraphEdit
class_name View


const skill_node_scene: PackedScene = preload("res://elements/skill_node/skill_node.tscn")
var skill_nodes: Dictionary[String, SkillNode] = {}
var move_tween : Tween
static var current_graph_view : View
@onready var clear_confirm_dialog: ConfirmationDialog = get_node_or_null("../ClearConfirmDialog")

func _ready() -> void:
	View.current_graph_view = self

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		_cancel_drag_operation_on_empty.call_deferred()
	
			
func _cancel_drag_operation_on_empty():
	if not DragContext.current_from_connector: return
	DragContext.cancel_connection_drag()
			
func _on_add_skill_button_pressed() -> void:
	var skill_node: SkillNode = skill_node_scene.instantiate()
	skill_node.connect("ready", func():
		skill_node.body.grab_focus.call_deferred()
		, CONNECT_ONE_SHOT)
	add_child(skill_node)
	
	var pos = (scroll_offset + size/2) / zoom 
	skill_node.position_offset = Vector2i(pos) - Vector2i(pos) % Vector2i(snapping_distance, snapping_distance)
	move_to(skill_node)

func clear_all():
	var nodes := (SkillNode.skill_node_register.values() as Array[SkillNode]).duplicate()
	for skill_node in nodes:
		skill_node.delete()
	SkillNode.skill_node_register = {}
	SkillNode.id_index = 0
	ConnectionEntry.connection_register = {}
	CustomPropertyContext.clear()

func _on_clear_button_pressed() -> void:
	if clear_confirm_dialog:
		clear_confirm_dialog.popup_centered()
	else:
		clear_all()

func move_to(node: SkillNode):
	if move_tween:
		move_tween.kill()
		move_tween = null
	move_tween = create_tween()
	move_tween.tween_property(self, "scroll_offset",node.position_offset * zoom - (size/2), 0.33).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)	#.set_deferred("scroll_offset", )
