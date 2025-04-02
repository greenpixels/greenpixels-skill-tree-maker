extends Control
class_name SkillNodeConnector

enum ANCHOR_DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	
	UP_LEFT,
	UP_RIGHT,
	
	DOWN_LEFT,
	DOWN_RIGHT
}

class ConnectionEntry:
	var line: Line2D
	var from : SkillNodeConnector
	var to : SkillNodeConnector
	func update():
		if line.points.size() < 2:
			line.add_point(Vector2.ZERO)
		if line.points.size() < 2:
			line.add_point(Vector2.ZERO)
		line.set_point_position(0, Vector2.ZERO)
		var new_pos = (to.skill_node_parent.position_offset + to.position) - (from.skill_node_parent.position_offset + from.position)
		line.set_point_position(1, new_pos)
		print(new_pos)

@export var skill_node_parent : SkillNode
@export var anchor_direction : ANCHOR_DIRECTION
@onready var line_connections : Control = %LineConnections
var connection_line_scene : PackedScene = preload("res://elements/connection_line/connection_line.tscn")
var connections : Array[ConnectionEntry] = []
var _is_hovered = false

signal connection_drag_start(connector: SkillNodeConnector)
signal connection_drag_end(connector: SkillNodeConnector)



func _input(event: InputEvent) -> void:
	if not _is_hovered:
		%Connector.modulate = Color.TRANSPARENT
		return
	%Connector.modulate = Color.WHITE
	if event is InputEventMouseButton: 
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			connection_drag_start.emit(self)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			connection_drag_end.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			_remove_connections()

func _remove_connections():
	for connection in connections:
		var to_index = 0
		for found_connection in connection.to.connections:
			if found_connection.line == connection.line:
				connection.to.connections.remove_at(to_index)
			to_index += 1
		var from_index = 0
		for found_connection in connection.from.connections:
			if found_connection.line == connection.line:
				connection.from.connections.remove_at(from_index)
			from_index += 1
		connection.line.queue_free()
		connections.clear()
				
func update_connections():
	for connection in connections:
		connection.update()

func add_connection(to: SkillNodeConnector):
	if to == self: return
	if not to.skill_node_parent: return
	var connection_line : Line2D = connection_line_scene.instantiate()
	line_connections.add_child(connection_line)
	
	handle_new_connection_added(self, to, connection_line)
	to.handle_new_connection_added(self, to, connection_line)

func handle_new_connection_added(from: SkillNodeConnector, to: SkillNodeConnector, line: Line2D):
	var connection_entry = ConnectionEntry.new()
	connection_entry.line = line
	connection_entry.from = from
	connection_entry.to = to
	connections.push_back(connection_entry)
	update_connections()
	
func _on_connector_mouse_entered() -> void:
	_is_hovered = true

func _on_connector_mouse_exited() -> void:
	_is_hovered = false
