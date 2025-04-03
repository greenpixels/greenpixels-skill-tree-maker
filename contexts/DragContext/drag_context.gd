extends Node

var current_from_connector: SkillNodeConnector = null
signal connection_drag_started
signal connection_drag_ended

func start_connection_drag(from: SkillNode, connector: SkillNodeConnector) -> void:
	current_from_connector = connector
	from.has_ongoing_connection_process = true
	connection_drag_started.emit()

func finish_connection_drag(to: SkillNode, connector: SkillNodeConnector) -> void:
	if connector == current_from_connector:
		current_from_connector.skill_node_parent.add_neighbour(connector)	
	elif current_from_connector and to != current_from_connector.skill_node_parent:
		current_from_connector.add_connection(connector)
	cancel_connection_drag()

func cancel_connection_drag() -> void:
	if not current_from_connector: return
	current_from_connector.skill_node_parent.has_ongoing_connection_process = false
	current_from_connector = null
	connection_drag_ended.emit()
