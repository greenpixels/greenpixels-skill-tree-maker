extends AcceptDialog

@onready var name_input: LineEdit = %NameInput
@onready var type_option: OptionButton = %TypeOption
@onready var add_button: Button = %AddButton
@onready var list_container: VBoxContainer = %ListContainer

func _ready() -> void:
	hide()
	add_button.pressed.connect(_on_add_pressed)
	CustomPropertyContext.custom_property_added.connect(_rebuild_list)
	CustomPropertyContext.custom_property_removed.connect(_rebuild_list)
	CustomPropertyContext.custom_property_renamed.connect(_rebuild_list)
	_rebuild_list()

func _on_add_pressed() -> void:
	var name := name_input.text.strip_edges()
	var type := type_option.selected
	CustomPropertyContext.add_custom_property(name, type)
	name_input.text = ""

func _rebuild_list(_arg1: Variant = null, _arg2: Variant = null) -> void:
	for child in list_container.get_children():
		child.queue_free()
	var props := CustomPropertyContext.get_custom_properties()
	for prop_name in props:
		var meta: Dictionary = props[prop_name]
		var type: int = meta["type"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_edit := LineEdit.new()
		name_edit.text = prop_name
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var type_label := Label.new()
		type_label.text = _type_name(type)
		type_label.custom_minimum_size = Vector2(70, 0)
		var captured_name := prop_name as String
		var rename_button := Button.new()
		rename_button.text = "Rename"
		rename_button.custom_minimum_size = Vector2(70, 0)
		rename_button.pressed.connect(func():
			var new_name := name_edit.text.strip_edges()
			if new_name != captured_name:
				CustomPropertyContext.rename_custom_property(captured_name, new_name)
		)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.custom_minimum_size = Vector2(70, 0)
		remove_button.pressed.connect(func():
			CustomPropertyContext.remove_custom_property(captured_name)
		)
		row.add_child(name_edit)
		row.add_child(type_label)
		row.add_child(rename_button)
		row.add_child(remove_button)
		list_container.add_child(row)

func _type_name(type: int) -> String:
	match type:
		CustomPropertyContext.TYPE.TEXT: return "Text"
		CustomPropertyContext.TYPE.BOOLEAN: return "Boolean"
		CustomPropertyContext.TYPE.DECIMAL: return "Decimal"
		CustomPropertyContext.TYPE.INTEGER: return "Integer"
	return "?"
