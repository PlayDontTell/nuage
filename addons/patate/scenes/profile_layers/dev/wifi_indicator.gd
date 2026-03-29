extends TextureRect

@export var connected_texture: Texture2D
@export var disconnected_texture: Texture2D
@export var check_interval: float = 5.0
@export var check_url: String = "https://1.1.1.1"

var _http: HTTPRequest
var _timer: Timer


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 3.0
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)

	_timer = Timer.new()
	_timer.wait_time = check_interval
	_timer.timeout.connect(_check)
	add_child(_timer)
	_timer.start()

	_check()


func _check() -> void:
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var err := _http.request(check_url, [], HTTPClient.METHOD_HEAD)
	if err != OK:
		texture = disconnected_texture


func _on_request_completed(result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS:
		texture = connected_texture
		modulate = Color.GREEN
	else:
		texture = disconnected_texture
		modulate = Color.RED
