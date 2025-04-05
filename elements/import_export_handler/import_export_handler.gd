extends Node

@onready var import_dialog := $ImportDialog
@onready var export_dialog := $ExportDialog
@onready var invalid_node_dialog := $InvalidNodeDialog
@onready var web_file_exchange := $WebFileExchange

var skill_node_scene = preload("res://elements/skill_node/skill_node.tscn")

func _ready() -> void:
	if web_file_exchange._check_is_web_platform():
		web_file_exchange.file_loaded.connect(_handle_web_import)

func _on_import_started():
	if not web_file_exchange._check_is_web_platform():
		import_dialog.show()
	else:
		web_file_exchange.open_load_file_dialog()

func _on_export_started():
	if not web_file_exchange._check_is_web_platform():
		export_dialog.show()
	else:
		var json = _generate_json_from_current_skill_tree()
		if not json:
			return
		web_file_exchange.download_file(json.to_utf8_buffer(), "skill_tree-" + Time.get_datetime_string_from_system() + ".gp.json")

func _generate_json_from_current_skill_tree() -> Variant:
	var data = {}
	data.nodes = []
	data.connections = []
	data.node_id_index = SkillNode.id_index
	data.connection_id_index = ConnectionEntry.id_index
	for skill_node in SkillNode.skill_node_register.values() as Array[SkillNode]:
		if skill_node.is_invalid:
			invalid_node_dialog.show()
			return false
		var node_data = {}
		node_data.id = skill_node.id
		node_data.key = skill_node.configuration.key
		node_data.max_points = skill_node.configuration.max_points
		node_data.needed_neighbour_point_sum = skill_node.configuration.needed_neighbour_point_sum
		node_data.position_x = skill_node.position_offset.x
		node_data.position_y = skill_node.position_offset.y
		data.nodes.push_back(node_data)
		
	for connection in ConnectionEntry.connection_register.values() as Array[ConnectionEntry]:
		var connection_data = {}
		connection_data.id = connection.id
		connection_data.from_skill_id = connection.from.skill_node_parent.id
		connection_data.from_anchor = SkillNodeConnector.ANCHOR_DIRECTION.keys()[connection.from.anchor_direction]
		connection_data.to_skill_id = connection.to.skill_node_parent.id
		connection_data.to_anchor = SkillNodeConnector.ANCHOR_DIRECTION.keys()[connection.to.anchor_direction]
		data.connections.push_back(connection_data)
	return JSON.stringify(data)


func _on_export_dialog_file_selected(path: String) -> void:
	var json = _generate_json_from_current_skill_tree()
	if not json: return
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json)

func _handle_import(data: Dictionary):
	if not data: 
		push_error("Invalid data")
		return
	View.current_graph_view.clear_all()

	if data.has("nodes") and data.nodes is Array:
		for node_data in data.nodes:
			var skill_node = skill_node_scene.instantiate() as SkillNode
			View.current_graph_view.add_child(skill_node)
			if not skill_node: continue
			if node_data.has("id"):
				skill_node.id = node_data.id
				SkillNode.skill_node_register[str(skill_node.id)] = skill_node
			if node_data.has("key") and not (node_data.key as String).is_empty():
				skill_node.set_key(node_data.key)
			if node_data.has("max_points"):
				skill_node.set_max_points(node_data.max_points)
			if node_data.has("needed_neighbour_point_sum"):
				skill_node.set_needed_neighbour_point_sum(node_data.needed_neighbour_point_sum)
			
			if node_data.has("position_x") and node_data.has("position_y"):
				skill_node.set_position_offset(Vector2(node_data.position_x, node_data.position_y))
	if data.has("connections") and data.connections is Array:
		for connection_data in data.connections:
			if connection_data.has("from_skill_id") and connection_data.has("to_skill_id") and connection_data.has("from_anchor") and connection_data.has("to_anchor"):
				if not SkillNode.skill_node_register.has(str(int(connection_data.from_skill_id))):
					continue
				if not SkillNode.skill_node_register.has(str(int(connection_data.to_skill_id))):
					continue
				var from : SkillNode = SkillNode.skill_node_register[str(int(connection_data.from_skill_id))] as SkillNode
				var to = SkillNode.skill_node_register[str(int(connection_data.to_skill_id))] as SkillNode
				var from_anchor_id = SkillNodeConnector.ANCHOR_DIRECTION[connection_data.from_anchor]
				var connector_from = from.get_connector_by_anchor_direction(from_anchor_id) as SkillNodeConnector
				var to_anchor_id = SkillNodeConnector.ANCHOR_DIRECTION[connection_data.to_anchor]
				var connector_to = to.get_connector_by_anchor_direction(to_anchor_id) as SkillNodeConnector
				connector_from.add_connection(connector_to)
				
		if data.has("node_id_index"):
			SkillNode.id_index = data.node_id_index
		if data.has("connection_id_index"):
			ConnectionEntry.id_index = data.connection_id_index

func _handle_web_import(buffer: PackedByteArray, file_type: String, file_name: String):
	if not file_name.ends_with(".gp.json"):
		push_error(file_name + " is not a valid skill-tree file.")
		return
	var file_content = buffer.get_string_from_utf8()
	_handle_import(JSON.parse_string(file_content))

func _on_import_dialog_file_selected(path: String) -> void:
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json_dict_as_string := file.get_line()
		if json_dict_as_string != null:
			_handle_import(JSON.parse_string(json_dict_as_string))
	
