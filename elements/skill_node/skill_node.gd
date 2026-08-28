extends GraphElement
class_name SkillNode

class Configuration:
	var image_path: String = ""
	var key: String = ""
	var max_points : int = 1
	var custom_properties: Dictionary = {}
	var internal_comment: String = ""
	
static var skill_node_register : Dictionary[String, SkillNode] = {}

@export var connectors: Array[SkillNodeConnector] = []
@onready var body: Control = %Body
@onready var status_border: Control = %StatusBorder
@onready var texture_rect: TextureRect = %TextureRect
@onready var max_points_label : Label = %MaxPointsLabel

static var id_index: int = 0
var id: int = 0

signal custom_properties_changed
signal id_changed

var is_invalid: bool = false:
	set(value):
		is_invalid = value
		_update_appearance()

var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_appearance()

var configuration: Configuration
var _default_texture: Texture2D
var _border_style: StyleBoxFlat
var _is_body_being_dragged: bool = false
var _has_started_drag_movement: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO
var _is_hovered: bool = false
var has_ongoing_connection_process: bool = false
var graph : GraphEdit

func _ready() -> void:
	id = id_index
	id_index += 1
	body.set_meta("skill_node", self)
	configuration = Configuration.new()
	_default_texture = texture_rect.texture
	_border_style = (status_border.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	status_border.add_theme_stylebox_override("panel", _border_style)
	CustomPropertyContext.ensure_property_on_node(self)
	validate()
	DragContext.connection_drag_started.connect(queue_redraw)
	DragContext.connection_drag_ended.connect(queue_redraw)
	graph = get_parent() as GraphEdit 
	Callable(func():
		skill_node_register[str(get_instance_id())] = self
		_validate_all_nodes()
	).call_deferred()
	
func _process(_delta: float) -> void:
	if has_ongoing_connection_process:
		queue_redraw()
		
	if _is_body_being_dragged:
		_update_node_position_while_dragging()

func _update_node_position_while_dragging() -> void:
	if _should_skip_movement_update():
		return
	_has_started_drag_movement = true
	var graph_mouse_position := _calculate_snapped_graph_position(graph)
	set_position_offset(graph_mouse_position)
	_update_all_connector_positions()

func _should_skip_movement_update() -> bool:
	return not _has_started_drag_movement and _last_mouse_position.distance_to(get_global_mouse_position()) < (get_parent() as GraphEdit).snapping_distance

func _convert_global_position_to_graph_position(graph: GraphEdit, position_to_calculate: Vector2) -> Vector2:
	return (graph.get_screen_transform() * position_to_calculate + graph.scroll_offset) / graph.zoom

func _calculate_snapped_graph_position(graph: GraphEdit) -> Vector2:
	var pos := _convert_global_position_to_graph_position(graph, get_global_mouse_position())
	if graph.snapping_enabled:
		pos = Vector2i(pos) - Vector2i(pos) % Vector2i(graph.snapping_distance, graph.snapping_distance)
	return pos

func _update_all_connector_positions() -> void:
	for connector in connectors:
		connector.update_connections()

func set_key(key: String) -> void:
	configuration.key = key
	validate()

func set_id(new_id: int) -> void:
	if new_id < 0:
		new_id = 0
	if id == new_id:
		return
	var old_id := id
	id = new_id
	id_changed.emit()
	_validate_all_nodes()

static func get_node_by_id(search_id: int) -> SkillNode:
	for skill_node in skill_node_register.values() as Array[SkillNode]:
		if skill_node.id == search_id:
			return skill_node
	return null

static func _validate_all_nodes() -> void:
	var id_counts: Dictionary = {}
	for skill_node in skill_node_register.values() as Array[SkillNode]:
		var key := str(skill_node.id)
		id_counts[key] = id_counts.get(key, 0) + 1
	for skill_node in skill_node_register.values() as Array[SkillNode]:
		skill_node.validate(id_counts[str(skill_node.id)] > 1)

func set_image(path: String) -> void:
	configuration.image_path = path
	if path.is_empty() or not FileAccess.file_exists(path):
		texture_rect.texture = _default_texture
	else:
		var img := Image.load_from_file(path)
		if img:
			texture_rect.texture = ImageTexture.create_from_image(img)
		else:
			texture_rect.texture = _default_texture
	validate()

func set_max_points(value : int):
	configuration.max_points = value
	max_points_label.text = str(configuration.max_points)

func set_internal_comment(comment: String) -> void:
	configuration.internal_comment = comment
	tooltip_text = comment
	body.tooltip_text = comment

func notify_custom_properties_changed() -> void:
	custom_properties_changed.emit()

func _update_appearance() -> void:
	if _border_style == null:
		return
	if is_invalid:
		_border_style.border_color = Color.RED
		_border_style.border_width_left = 2
		_border_style.border_width_top = 2
		_border_style.border_width_right = 2
		_border_style.border_width_bottom = 2
	elif is_selected:
		_border_style.border_color = Color.YELLOW
		_border_style.border_width_left = 3
		_border_style.border_width_top = 3
		_border_style.border_width_right = 3
		_border_style.border_width_bottom = 3
	else:
		_border_style.border_color = Color(0.458405, 0.458405, 0.458405, 1)
		_border_style.border_width_left = 2
		_border_style.border_width_top = 2
		_border_style.border_width_right = 2
		_border_style.border_width_bottom = 2
	status_border.queue_redraw()

func validate(id_collision: bool = false) -> void:
	is_invalid = configuration.key.strip_edges().is_empty() or id_collision
func delete() -> void:
	for connector in connectors:
		connector._remove_connections()
	if skill_node_register.has(str(get_instance_id())):
		skill_node_register.erase(str(get_instance_id()))
	_validate_all_nodes()
	queue_free()

func _on_connector_connection_drag_end(connector: SkillNodeConnector) -> void:
	DragContext.finish_connection_drag(self, connector)


func _on_connector_connection_drag_start(connector: SkillNodeConnector) -> void:
	DragContext.start_connection_drag(self, connector)

func _on_body_button_down() -> void:
	_is_body_being_dragged = true
	_has_started_drag_movement = false
	_last_mouse_position = get_global_mouse_position()

func _on_body_button_up() -> void:
	_is_body_being_dragged = false

func _on_body_mouse_entered() -> void:
	_is_hovered = true

func _on_body_mouse_exited() -> void:
	_is_hovered = false

func _check_is_already_connected(to: SkillNode):
	for connector in connectors:
		for connection in  connector.connections:
			if connection.to.skill_node_parent == to:
				return true
	return false

func add_neighbour(connector : SkillNodeConnector):
	var neighbour = load("res://elements/skill_node/skill_node.tscn").instantiate() as SkillNode
	
	graph.add_child.call_deferred(neighbour)
	neighbour.set_position_offset(_convert_global_position_to_graph_position(graph, global_position) + sign(connector.global_position - global_position) * graph.snapping_distance * 5)
	match connector.anchor_direction:
		SkillNodeConnector.ANCHOR_DIRECTION.UP: 
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.DOWN))
		SkillNodeConnector.ANCHOR_DIRECTION.DOWN:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.UP))
		SkillNodeConnector.ANCHOR_DIRECTION.LEFT:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.RIGHT))
		SkillNodeConnector.ANCHOR_DIRECTION.RIGHT:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.LEFT))
		SkillNodeConnector.ANCHOR_DIRECTION.UP_LEFT:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.DOWN_RIGHT))
		SkillNodeConnector.ANCHOR_DIRECTION.UP_RIGHT:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.DOWN_LEFT))
		SkillNodeConnector.ANCHOR_DIRECTION.DOWN_LEFT:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.UP_RIGHT))
		SkillNodeConnector.ANCHOR_DIRECTION.DOWN_RIGHT:
			connector.add_connection(neighbour.get_connector_by_anchor_direction(SkillNodeConnector.ANCHOR_DIRECTION.UP_LEFT))
	_update_all_connector_positions.call_deferred()
	neighbour.connect("ready", func():
		neighbour.body.grab_focus.call_deferred()
		graph.move_to(neighbour)
		, CONNECT_ONE_SHOT)
	

func get_connector_by_anchor_direction(anchor_direction: SkillNodeConnector.ANCHOR_DIRECTION):
	match anchor_direction:
		SkillNodeConnector.ANCHOR_DIRECTION.UP: return %TopConnector
		SkillNodeConnector.ANCHOR_DIRECTION.DOWN: return %DownConnector
		SkillNodeConnector.ANCHOR_DIRECTION.LEFT: return %LeftConnector
		SkillNodeConnector.ANCHOR_DIRECTION.RIGHT: return %RightConnector
		SkillNodeConnector.ANCHOR_DIRECTION.UP_LEFT: return %TopLeftConnector
		SkillNodeConnector.ANCHOR_DIRECTION.UP_RIGHT: return %TopRightConnector
		SkillNodeConnector.ANCHOR_DIRECTION.DOWN_LEFT: return %BottomLeftConnector
		SkillNodeConnector.ANCHOR_DIRECTION.DOWN_RIGHT: return %BottomRightConnector
	return null

func _draw() -> void:
	if has_ongoing_connection_process:
		for connector in connectors:
			if DragContext.current_from_connector == connector:
				draw_line(
					_convert_global_position_to_graph_position(graph, connector.global_position) - _convert_global_position_to_graph_position(graph, global_position),
					_convert_global_position_to_graph_position(graph, graph.get_global_mouse_position())  - _convert_global_position_to_graph_position(graph, global_position),
					Color.from_rgba8(255, 255, 255, 80),
					2
				)
				return
