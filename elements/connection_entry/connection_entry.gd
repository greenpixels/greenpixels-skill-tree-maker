extends RefCounted
class_name ConnectionEntry

static var id_index = 0 
static var connection_register : Dictionary[String, ConnectionEntry] = {}

var id = id_index
var line: Line2D
var from: SkillNodeConnector
var to: SkillNodeConnector

func _init():
	id_index += 1
	Callable(func(): ConnectionEntry.connection_register[str(id)] = self).call_deferred()
	
func update() -> void:
	_ensure_line_points()
	var new_pos := (to.skill_node_parent.position_offset + to.position) - (from.skill_node_parent.position_offset + from.position)
	line.set_point_position(1, new_pos)

func _ensure_line_points() -> void:
	if line.points.size() < 2:
		line.add_point(Vector2.ZERO)
	if line.points.size() < 2:
		line.add_point(Vector2.ZERO)
	line.set_point_position(0, Vector2.ZERO)
