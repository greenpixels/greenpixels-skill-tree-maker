extends GraphElement
class_name SkillNode

class Configuration:
	var image_path : String = ""
	var key : String = ""
	
@export var connectors : Array[SkillNodeConnector] = []

static var id_index = 0
var id = 0

var _is_invalid = false :
	set(value):
		_is_invalid = value
		%StatusBorder.modulate = Color.RED if _is_invalid else Color.WHITE
		
var configuration : Configuration
var _is_body_being_dragged := false
var _last_mouse_position = Vector2.ZERO

func _process(delta: float) -> void:
	if _is_body_being_dragged:
		if _last_mouse_position.distance_to(get_global_mouse_position()) < (get_parent() as GraphEdit).snapping_distance:
			return
		var graph = get_parent() as GraphEdit
		var graph_mouse_position = (graph.get_local_mouse_position() + graph.scroll_offset) / graph.zoom
		if graph.snapping_enabled:
			graph_mouse_position = Vector2i(graph_mouse_position) - Vector2i(graph_mouse_position) % Vector2i(graph.snapping_distance, graph.snapping_distance)
		set_position_offset(graph_mouse_position)
		for connector in connectors:
			connector.update_connections()

func _ready() -> void:
	id = id_index
	id_index += 1
	%Body.set_meta("skill_node", self)
	configuration = Configuration.new()
	validate()

func set_key(key: String):
	configuration.key = key
	validate()

func set_image(path: String):
	configuration.image_path = path
	%TextureRect.texture = ImageTexture.create_from_image(Image.load_from_file(configuration.image_path))
	validate()

func validate():
	_is_invalid = configuration.key.strip_edges().is_empty()
		
func delete():
	for connector in connectors:
		connector._remove_connections()
	queue_free()

func _on_connector_connection_drag_end(connector: SkillNodeConnector) -> void:
	DragContext.stop_drag(self, connector)

func _on_connector_connection_drag_start(connector: SkillNodeConnector) -> void:
	DragContext.start_drag(self, connector)

func _on_body_button_down() -> void:
	_is_body_being_dragged = true
	_last_mouse_position = get_global_mouse_position()

func _on_body_button_up() -> void:
	_is_body_being_dragged = false
