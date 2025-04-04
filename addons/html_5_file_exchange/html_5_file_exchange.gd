extends Node
class_name Html5FileExchange

signal file_loaded(buffer: PackedByteArray, file_type: String, file_name: String)

var js_callback: JavaScriptObject
var js_interface: JavaScriptObject

static var _js_initialized := false

func _ready() -> void:
	if not _check_is_web_platform(): return
	_init_js()

func _init_js(javascript_file_path = "res://addons/html_5_file_exchange/exchange.js") -> void:
	if not FileAccess.file_exists(javascript_file_path):
		push_error("JavaScript file not found at  " + javascript_file_path)
		return
		
	var file := FileAccess.open(javascript_file_path, FileAccess.READ)
	var js_code := file.get_as_text()
	file.close()
	
	JavaScriptBridge.eval(js_code, true)
	js_callback = JavaScriptBridge.create_callback(load_handler)
	js_interface = JavaScriptBridge.get_interface("__html5FileExchange")

func load_handler(_args) -> void:
	var file_type = js_interface.fileType
	var file_name = js_interface.fileName
	var file_data = JavaScriptBridge.eval("__html5FileExchange.result", true)
	file_loaded.emit(file_data, file_type, file_name)

func open_load_file_dialog() -> void:
	if not _check_is_web_platform(): return
	js_interface.upload(js_callback)

# Could eventually use
# https://developer.mozilla.org/en-US/docs/Web/API/Window/showSaveFilePicker#browser_compatibility
# But not that well supported at the moment

func download_file(buffer: PackedByteArray, file_name: String) -> void:
	if not _check_is_web_platform(): return
	JavaScriptBridge.download_buffer(buffer, file_name)

func _check_is_web_platform() -> bool:
	return OS.get_name() == "Web" and JavaScriptBridge.eval("typeof window != 'undefined'")
