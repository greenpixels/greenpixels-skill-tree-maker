extends PanelContainer

@export var image_file_dialog : FileDialog
@export var file_path_input : LineEdit

var current_selected_skill_node : SkillNode = null :
	set(value):
		current_selected_skill_node = value
		if current_selected_skill_node:
			show()
			%KeyInput.text = current_selected_skill_node.configuration.key
			%FilePathInput.text = current_selected_skill_node.configuration.image_path
		else: 
			hide()

func select_skill_node(node: SkillNode):
	current_selected_skill_node = node

func _ready() -> void:
	hide()
	get_viewport().gui_focus_changed.connect(func(control: Control):
		if control is Button and control.has_meta("skill_node"):
			select_skill_node(control.get_meta("skill_node"))
	)

func _on_file_path_button_pressed() -> void:
	image_file_dialog.show()

func _on_image_file_dialog_file_selected(path: String) -> void:
	image_file_dialog.hide()
	var image = Image.load_from_file(path)
	if not image: return
	print(path)
	var file_name_array = path.split("/")
	var file_user_path = "user://images/" + file_name_array[-1]
	print(file_user_path)
	file_path_input.text = file_user_path
	
	
	if not DirAccess.open("user://images"):
		var user_dir = DirAccess.open("user://")
		user_dir.make_dir("user://images")
		
	image.save_png(file_user_path)
	current_selected_skill_node.set_image(file_user_path)

func _on_key_input_text_changed(new_text: String) -> void:
	current_selected_skill_node.configuration.key = new_text
	current_selected_skill_node.set_key(new_text)

func _on_delete_button_pressed() -> void:
	current_selected_skill_node.delete()
	current_selected_skill_node = null
