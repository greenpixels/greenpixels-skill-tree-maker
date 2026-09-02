extends PanelContainer

@export var image_file_dialog: FileDialog
@export var save_image_file_dialog: FileDialog

@onready var key_input: LineEdit = %KeyInput
@onready var id_input: SpinBox = %IdInput
@onready var internal_comment_input: TextEdit = %InternalCommentInput
@onready var image_preview: TextureRect = %ImagePreview
@onready var max_points_input : SpinBox = %MaxPointsInput
@onready var custom_properties_container: VBoxContainer = %CustomPropertiesContainer
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog
@onready var download_button: Button = %DownloadImageButton

var selected_skill_node: SkillNode = null:
	set(value):
		if selected_skill_node and is_instance_valid(selected_skill_node):
			selected_skill_node.custom_properties_changed.disconnect(_refresh_custom_properties)
			selected_skill_node.is_selected = false
			if selected_skill_node.tree_exited.is_connected(_on_selected_node_freed):
				selected_skill_node.tree_exited.disconnect(_on_selected_node_freed)
		selected_skill_node = value
		if selected_skill_node:
			show()
			key_input.text = selected_skill_node.configuration.key
			id_input.value = selected_skill_node.id
			internal_comment_input.text = selected_skill_node.configuration.internal_comment
			_refresh_image_preview()
			max_points_input.value = selected_skill_node.configuration.max_points
			selected_skill_node.is_selected = true
			selected_skill_node.custom_properties_changed.connect(_refresh_custom_properties)
			if not selected_skill_node.tree_exited.is_connected(_on_selected_node_freed):
				selected_skill_node.tree_exited.connect(_on_selected_node_freed)
			_refresh_custom_properties()
		else:
			hide()

func _ready() -> void:
	hide()
	_initialize_focus_change_handler()
	CustomPropertyContext.custom_property_added.connect(_refresh_custom_properties)
	CustomPropertyContext.custom_property_removed.connect(_refresh_custom_properties)
	CustomPropertyContext.custom_property_renamed.connect(_refresh_custom_properties)

func _initialize_focus_change_handler() -> void:
	get_viewport().gui_focus_changed.connect(func(control: Control):
		if SkillNode.skill_node_register.values().is_empty():
			update_selected_skill_node(null)
			return
		if control is Button and control.has_meta("skill_node"):
			update_selected_skill_node(control.get_meta("skill_node"))
	)

func _input(event: InputEvent) -> void:
	if selected_skill_node and event.is_action("ui_graph_delete"):
		_on_delete_button_pressed()

func update_selected_skill_node(node: SkillNode) -> void:
	selected_skill_node = node

func _on_selected_node_freed() -> void:
	selected_skill_node = null

func _refresh_image_preview() -> void:
	if not selected_skill_node or not is_instance_valid(selected_skill_node):
		image_preview.texture = null
		download_button.disabled = true
		return
	image_preview.texture = selected_skill_node.texture_rect.texture
	download_button.disabled = selected_skill_node.configuration.image_path.is_empty()

func process_selected_image(path: String) -> void:
	var image := Image.load_from_file(path)
	if not image:
		return

	var file_name_array := path.split("/")
	var file_user_path := "user://images/" + file_name_array[-1]

	_create_images_directory_if_needed()
	image.save_png(file_user_path)
	selected_skill_node.set_image(file_user_path)
	_refresh_image_preview()

func _create_images_directory_if_needed() -> void:
	if not DirAccess.dir_exists_absolute("user://images"):
		DirAccess.make_dir_absolute("user://images")

func _on_file_path_button_pressed() -> void:
	image_file_dialog.show()

func _on_image_file_dialog_file_selected(path: String) -> void:
	image_file_dialog.hide()
	process_selected_image(path)

func _on_key_input_text_changed(new_text: String) -> void:
	selected_skill_node.set_key(new_text)

func _on_id_input_value_changed(value: float) -> void:
	if not is_instance_valid(selected_skill_node): return
	selected_skill_node.set_id(int(value))

func _on_internal_comment_input_text_changed() -> void:
	selected_skill_node.set_internal_comment(internal_comment_input.text)

func _on_max_points_input_value_changed(value: float) -> void:
	selected_skill_node.set_max_points(int(value))

func _on_delete_button_pressed() -> void:
	if not is_instance_valid(selected_skill_node): return
	delete_confirm_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	if not is_instance_valid(selected_skill_node): return
	selected_skill_node.delete()
	selected_skill_node = null

func _on_custom_properties_settings_pressed() -> void:
	var modal := get_node_or_null("/root/Main/CustomPropertiesEdit")
	if modal:
		modal.popup_centered()

func _on_download_image_button_pressed() -> void:
	if not is_instance_valid(selected_skill_node): return
	var path := selected_skill_node.configuration.image_path
	if path.is_empty() or not FileAccess.file_exists(path): return
	var buffer := FileAccess.get_file_as_bytes(path)
	if buffer.is_empty(): return
	if _is_web_platform():
		_web_download(buffer)
	else:
		save_image_file_dialog.current_file = _default_image_file_name()
		save_image_file_dialog.popup_centered()

func _on_save_image_dialog_file_selected(path: String) -> void:
	save_image_file_dialog.hide()
	if not is_instance_valid(selected_skill_node): return
	var src_path := selected_skill_node.configuration.image_path
	if src_path.is_empty() or not FileAccess.file_exists(src_path): return
	var buffer := FileAccess.get_file_as_bytes(src_path)
	if buffer.is_empty(): return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open file for writing: " + path)
		return
	file.store_buffer(buffer)
	file.close()

func _is_web_platform() -> bool:
	return OS.get_name() == "Web"

func _web_download(buffer: PackedByteArray) -> void:
	var web: Html5FileExchange = _get_web_file_exchange()
	if web:
		web.download_file(buffer, _default_image_file_name())

func _get_web_file_exchange():
	var handler := get_node_or_null("/root/Main/ImportExportHandler")
	if handler and handler.has_node("WebFileExchange"):
		return handler.get_node("WebFileExchange")
	return null

func _default_image_file_name() -> String:
	var key := selected_skill_node.configuration.key
	var name := key if not key.is_empty() else "skill_image"
	return name + ".png"

func _refresh_custom_properties(_a: Variant = null, _b: Variant = null) -> void:
	if not selected_skill_node or not is_instance_valid(selected_skill_node):
		return
	for child in custom_properties_container.get_children():
		child.queue_free()
	var props := CustomPropertyContext.get_custom_properties()
	var node_props := selected_skill_node.configuration.custom_properties
	for prop_name in props:
		var type: int = CustomPropertyContext.get_custom_property_type(prop_name)
		if not node_props.has(prop_name):
			node_props[prop_name] = _default_value_for_type(type)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var label := Label.new()
		label.text = prop_name
		label.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)
		var captured_name := prop_name as String
		match type:
			CustomPropertyContext.TYPE.TEXT:
				var edit := LineEdit.new()
				edit.text = node_props[prop_name]
				edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				edit.text_changed.connect(func(new_text: String):
					selected_skill_node.configuration.custom_properties[captured_name] = new_text
				)
				row.add_child(edit)
			CustomPropertyContext.TYPE.BOOLEAN:
				var check := CheckBox.new()
				check.button_pressed = node_props[prop_name]
				check.toggled.connect(func(pressed: bool):
					selected_skill_node.configuration.custom_properties[captured_name] = pressed
				)
				row.add_child(check)
			CustomPropertyContext.TYPE.DECIMAL:
				var spin : SpinBox = SpinBox.new()
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.step = 0.1
				spin.value = node_props[prop_name]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				spin.value_changed.connect(func(value: float):
					selected_skill_node.configuration.custom_properties[captured_name] = value
				)
				row.add_child(spin)
			CustomPropertyContext.TYPE.INTEGER:
				var spin : SpinBox = SpinBox.new()
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.rounded = true
				spin.value = node_props[prop_name]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				spin.value_changed.connect(func(value: float):
					selected_skill_node.configuration.custom_properties[captured_name] = int(value)
				)
				row.add_child(spin)
		custom_properties_container.add_child(row)

func _default_value_for_type(type: int) -> Variant:
	match type:
		CustomPropertyContext.TYPE.TEXT: return ""
		CustomPropertyContext.TYPE.BOOLEAN: return false
		CustomPropertyContext.TYPE.DECIMAL: return 0.0
		CustomPropertyContext.TYPE.INTEGER: return 0
	return null
