extends Node

enum TYPE { TEXT, BOOLEAN, DECIMAL, INTEGER }

signal custom_property_added(name: String, type: int)
signal custom_property_removed(name: String)
signal custom_property_renamed(old_name: String, new_name: String)

# name -> { "type": int }
var _custom_properties: Dictionary = {}

func get_custom_properties() -> Dictionary:
	return _custom_properties

func get_custom_property_type(name: String) -> int:
	if not _custom_properties.has(name):
		return -1
	return _custom_properties[name]["type"]

func has_custom_property(name: String) -> bool:
	return _custom_properties.has(name)

func add_custom_property(name: String, type: int) -> void:
	if name.is_empty() or _custom_properties.has(name):
		return
	_custom_properties[name] = {"type": type}
	for skill_node in SkillNode.skill_node_register.values() as Array[SkillNode]:
		if not skill_node.configuration.custom_properties.has(name):
			skill_node.configuration.custom_properties[name] = _default_value_for_type(type)
			skill_node.notify_custom_properties_changed()
	custom_property_added.emit(name, type)

func remove_custom_property(name: String) -> void:
	if not _custom_properties.has(name):
		return
	_custom_properties.erase(name)
	for skill_node in SkillNode.skill_node_register.values() as Array[SkillNode]:
		if skill_node.configuration.custom_properties.has(name):
			skill_node.configuration.custom_properties.erase(name)
			skill_node.notify_custom_properties_changed()
	custom_property_removed.emit(name)

func rename_custom_property(old_name: String, new_name: String) -> void:
	if not _custom_properties.has(old_name) or new_name.is_empty() or _custom_properties.has(new_name):
		return
	var meta: Dictionary = _custom_properties[old_name]
	_custom_properties.erase(old_name)
	_custom_properties[new_name] = meta
	for skill_node in SkillNode.skill_node_register.values() as Array[SkillNode]:
		if skill_node.configuration.custom_properties.has(old_name):
			var value = skill_node.configuration.custom_properties[old_name]
			skill_node.configuration.custom_properties.erase(old_name)
			skill_node.configuration.custom_properties[new_name] = value
			skill_node.notify_custom_properties_changed()
	custom_property_renamed.emit(old_name, new_name)

func ensure_property_on_node(skill_node: SkillNode) -> void:
	for prop_name in _custom_properties:
		if not skill_node.configuration.custom_properties.has(prop_name):
			skill_node.configuration.custom_properties[prop_name] = _default_value_for_type(_custom_properties[prop_name]["type"])

func _default_value_for_type(type: int) -> Variant:
	match type:
		TYPE.TEXT: return ""
		TYPE.BOOLEAN: return false
		TYPE.DECIMAL: return 0.0
		TYPE.INTEGER: return 0
	return null

func clear() -> void:
	_custom_properties.clear()