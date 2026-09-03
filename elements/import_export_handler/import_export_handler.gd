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
		web_file_exchange.download_file(json.to_utf8_buffer(), "skill_tree-" + Time.get_datetime_string_from_system() + ".gp-skill.json")

func _generate_json_from_current_skill_tree() -> Variant:
	var data = {}
	data.nodes = []
	data.connections = []
	data.node_id_index = SkillNode.id_index
	data.connection_id_index = ConnectionEntry.id_index
	var global_props := CustomPropertyContext.get_custom_properties()
	var exported_props := []
	for prop_name in global_props:
		var meta: Dictionary = global_props[prop_name]
		exported_props.push_back({
			"name": prop_name,
			"type": CustomPropertyContext.TYPE.keys()[meta["type"]]
		})
	data.custom_property_definitions = exported_props
	for skill_node in SkillNode.skill_node_register.values() as Array[SkillNode]:
		if skill_node.is_invalid:
			invalid_node_dialog.show()
			return false
		var node_data = {}
		node_data.id = skill_node.id
		node_data.key = skill_node.configuration.key
		node_data.max_points = skill_node.configuration.max_points
		node_data.internal_comment = skill_node.configuration.internal_comment
		node_data.position_x = skill_node.position_offset.x
		node_data.position_y = skill_node.position_offset.y
		if not skill_node.configuration.image_path.is_empty():
			var img := Image.load_from_file(skill_node.configuration.image_path)
			if img:
				node_data.image_base64 = Marshalls.raw_to_base64(img.save_png_to_buffer())
		node_data.custom_properties = skill_node.configuration.custom_properties.duplicate(true)
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

func _ensure_images_directory() -> void:
	if not DirAccess.dir_exists_absolute("user://images"):
		DirAccess.make_dir_absolute("user://images")

func _handle_import(data: Dictionary):
	if not data: 
		push_error("Invalid data")
		return
	View.current_graph_view.clear_all()

	if data.has("custom_property_definitions"):
		var defs = data.custom_property_definitions
		if defs is Array:
			for entry in defs:
				if entry is Dictionary:
					var prop_name: String = entry.get("name", "")
					var type_name: String = entry.get("type", "")
					if not prop_name.is_empty() and CustomPropertyContext.TYPE.has(type_name):
						CustomPropertyContext.add_custom_property(prop_name, CustomPropertyContext.TYPE[type_name])
		elif defs is Dictionary:
			for prop_name in defs:
				var entry = defs[prop_name]
				var type_name: String = ""
				if entry is Dictionary:
					type_name = entry.get("type", "")
				elif entry is String:
					type_name = entry
				if CustomPropertyContext.TYPE.has(type_name):
					CustomPropertyContext.add_custom_property(prop_name, CustomPropertyContext.TYPE[type_name])

	if data.has("nodes") and data.nodes is Array:
		for node_data in data.nodes:
			var skill_node = skill_node_scene.instantiate() as SkillNode
			View.current_graph_view.add_child(skill_node)
			if not skill_node: continue
			if node_data.has("id"):
				skill_node.set_id(node_data.id)
			if node_data.has("key") and not (node_data.key as String).is_empty():
				skill_node.set_key(node_data.key)
			if node_data.has("max_points"):
				skill_node.set_max_points(node_data.max_points)
			if node_data.has("internal_comment"):
				skill_node.set_internal_comment(node_data.internal_comment)
			if node_data.has("image_base64") and not (node_data.image_base64 as String).is_empty():
				var img := Image.new()
				var err := img.load_png_from_buffer(Marshalls.base64_to_raw(node_data.image_base64))
				if err == OK:
					var file_name := "img_" + str(skill_node.id) + ".png"
					var user_path := "user://images/" + file_name
					_ensure_images_directory()
					img.save_png(user_path)
					skill_node.set_image(user_path)
			if node_data.has("custom_properties"):
				skill_node.configuration.custom_properties = node_data.custom_properties.duplicate(true)
				skill_node.notify_custom_properties_changed()
			if node_data.has("position_x") and node_data.has("position_y"):
				skill_node.set_position_offset(Vector2(node_data.position_x, node_data.position_y))
	if data.has("connections") and data.connections is Array:
		var connections_data: Array = data.connections
		Callable(func():
			for connection_data in connections_data:
				if connection_data.has("from_skill_id") and connection_data.has("to_skill_id") and connection_data.has("from_anchor") and connection_data.has("to_anchor"):
					var from : SkillNode = SkillNode.get_node_by_id(int(connection_data.from_skill_id))
					var to : SkillNode = SkillNode.get_node_by_id(int(connection_data.to_skill_id))
					if not from or not to:
						continue
					var from_anchor_id = SkillNodeConnector.ANCHOR_DIRECTION[connection_data.from_anchor]
					var connector_from = from.get_connector_by_anchor_direction(from_anchor_id) as SkillNodeConnector
					var to_anchor_id = SkillNodeConnector.ANCHOR_DIRECTION[connection_data.to_anchor]
					var connector_to = to.get_connector_by_anchor_direction(to_anchor_id) as SkillNodeConnector
					connector_from.add_connection(connector_to)
		).call_deferred()
		if data.has("node_id_index"):
			SkillNode.id_index = data.node_id_index
		if data.has("connection_id_index"):
			ConnectionEntry.id_index = data.connection_id_index
	Callable(SkillNode._validate_all_nodes).call_deferred()

func _handle_web_import(buffer: PackedByteArray, file_type: String, file_name: String):
	if not file_name.ends_with(".gp-skill.json"):
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
	
