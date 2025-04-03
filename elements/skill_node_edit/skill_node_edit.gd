extends PanelContainer

@export var image_file_dialog: FileDialog
@export var file_path_input: LineEdit

@onready var key_input: LineEdit = %KeyInput
@onready var file_path_display: LineEdit = %FilePathInput
@onready var max_points_input : SpinBox = %MaxPointsInput
@onready var needed_points_input : SpinBox = %NeededPointsInput

var selected_skill_node: SkillNode = null:
	set(value):
		selected_skill_node = value
		if selected_skill_node:
			show()
			key_input.text = selected_skill_node.configuration.key
			file_path_display.text = selected_skill_node.configuration.image_path
			needed_points_input.value = selected_skill_node.configuration.needed_neighbour_point_sum
			max_points_input.value = selected_skill_node.configuration.max_points
		else: 
			hide()

func _ready() -> void:
	hide()
	_initialize_focus_change_handler()

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

func process_selected_image(path: String) -> void:
	var image := Image.load_from_file(path)
	if not image:
		return
		
	var file_name_array := path.split("/")
	var file_user_path := "user://images/" + file_name_array[-1]
	file_path_input.text = file_user_path
	
	_create_images_directory_if_needed()
	image.save_png(file_user_path)
	selected_skill_node.set_image(file_user_path)

func _create_images_directory_if_needed() -> void:
	if not DirAccess.open("user://images"):
		var user_dir := DirAccess.open("user://")
		user_dir.make_dir("user://images")

func _on_file_path_button_pressed() -> void:
	image_file_dialog.show()

func _on_image_file_dialog_file_selected(path: String) -> void:
	image_file_dialog.hide()
	process_selected_image(path)

func _on_key_input_text_changed(new_text: String) -> void:
	selected_skill_node.set_key(new_text)

func _on_max_points_input_value_changed(value: float) -> void:
	selected_skill_node.set_max_points(int(value))

func _on_needed_points_input_value_changed(value: float) -> void:
	selected_skill_node.set_needed_neighbour_point_sum(int(value))

func _on_delete_button_pressed() -> void:
	if not is_instance_valid(selected_skill_node): return
	selected_skill_node.delete()
	selected_skill_node = null
