extends Node


var _has_ongoing_connection_process := false
var current_from_connector : SkillNodeConnector = null

func start_drag(_from : SkillNode, connector: SkillNodeConnector):
	current_from_connector = connector

func stop_drag(to: SkillNode, connector: SkillNodeConnector):
	if not current_from_connector or to == current_from_connector.skill_node_parent:
		cancel_drag()
		return
	current_from_connector.add_connection(connector)

func cancel_drag():
	current_from_connector = null
