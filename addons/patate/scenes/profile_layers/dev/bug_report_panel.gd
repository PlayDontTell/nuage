extends Control

@onready var debug_layer: CanvasLayer = get_parent()

@onready var bug_category_option: OptionButton = %BugCategoryOption
@onready var bug_description_input: TextEdit = %BugDescriptionInput
@onready var bug_screenshot_preview: TextureRect = %BugScreenshot
@onready var include_screenshot_checkbox: CheckBox = %IncludeScreenshot
@onready var bug_screenshot_big: TextureRect = %BugScreenshotBig
@onready var bug_screenshot_big_full_screen: MarginContainer = %BugScreenshotBigFullScreen


var _bug_screenshot: Image = null


func _ready() -> void:
	self.hide()


func _on_bug_btn_pressed() -> void:
	_on_include_screenshot_toggled()

	bug_category_option.clear()
	for category in debug_layer.bug_categories:
		bug_category_option.add_item(category)
	bug_description_input.text = ""
	var native := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)

	var visible_debug_layer : bool = debug_layer.visible
	if visible_debug_layer:
		debug_layer.hide()
	SaveManager.before_screenshot.emit()
	await get_tree().process_frame

	_bug_screenshot = await debug_layer._render_to_image(native)

	if _bug_screenshot:
		bug_screenshot_preview.texture = ImageTexture.create_from_image(_bug_screenshot)
		bug_screenshot_big.texture = bug_screenshot_preview.texture
		bug_screenshot_preview.show()
		bug_screenshot_big.show()
		include_screenshot_checkbox.button_pressed = true
	else:
		bug_screenshot_preview.hide()
		bug_screenshot_big.hide()

	SaveManager.after_screenshot.emit()
	if visible_debug_layer:
		debug_layer.show()

	PauseManager.request_pause(self, true)
	self.show()


func _on_cancel_btn_pressed() -> void:
	self.hide()
	PauseManager.request_pause(self, false)
	_bug_screenshot = null


func _on_confirm_btn_pressed() -> void:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var folder := "user://_bug_reports/%s/" % timestamp
	DirAccess.make_dir_recursive_absolute(folder)

	if _bug_screenshot and include_screenshot_checkbox.button_pressed:
		_bug_screenshot.save_png(folder + "screenshot.png")
		_bug_screenshot = null

	var data := collect_data()
	data.category = bug_category_option.get_item_text(bug_category_option.selected)
	data.description = bug_description_input.text
	save_report(data, folder)

	var save_path := SaveManager.current_save_file_path
	if save_path != "" and FileAccess.file_exists(save_path):
		var src := FileAccess.get_file_as_bytes(save_path)
		var dst := FileAccess.open(folder + "save_data.sav", FileAccess.WRITE)
		if dst:
			dst.store_buffer(src)
			dst.close()

	if SaveManager.save_data:
		var json_file := FileAccess.open(folder + "save_data.json", FileAccess.WRITE)
		if json_file:
			json_file.store_string(JSON.stringify(inst_to_dict(SaveManager.save_data), "\t"))
			json_file.close()

	self.hide()
	PauseManager.request_pause(self, false)
	print("Bug report saved to: ", folder)


func collect_data() -> Dictionary:
	var rd := RenderingServer.get_rendering_device()
	return {
		"category": "",
		"description": "",
		"timestamp": Time.get_datetime_string_from_system(),
		"game": {
			"version": ProjectSettings.get_setting("application/config/version"),
			"release_mode": str(G.ReleaseMode.find_key(G.config.release_mode)),
			"core_scene": str(G.core_scene),
			"locale": SettingsManager.settings.lang,
			"time_played": SaveManager.save_data.time_played if SaveManager.save_data else 0.0,
			"time_since_start": SaveManager.save_data.time_since_start if SaveManager.save_data else 0.0,
			"real_time_s": snappedf(Time.get_ticks_msec() / 1000.0, 0.01),
			"paused": get_tree().paused,
			"pause_requests": PauseManager.request_pause_objects.size() - 1,
			"time_scale": Engine.time_scale,
		},
		"performance": {
			"fps": Engine.get_frames_per_second(),
			"process_delta_ms": snappedf(debug_layer._last_process_delta * 1000.0, 0.01),
			"physics_delta_ms": snappedf(debug_layer._last_physics_delta * 1000.0, 0.01),
			"audio_latency_ms": snappedf(Performance.get_monitor(Performance.AUDIO_OUTPUT_LATENCY) * 1000.0, 0.01),
			"memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01),
			"vram_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.01),
			"buffer_mb": snappedf(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, 0.01),
			"texture_memory_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.01),
			"nodes": get_tree().get_node_count(),
			"orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
			"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
			"tweens": get_tree().get_processed_tweens().size(),
			"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
			"physics_2d": int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)),
			"physics_3d": int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)),
		},
		"machine": {
			"model": OS.get_model_name(),
			"os": OS.get_name(),
			"os_version": OS.get_version(),
			"browser": JavaScriptBridge.eval("navigator.userAgent") if OS.get_name() == "Web" else "",
			"gpu": rd.get_device_name() if rd else "N/A",
			"cpu": OS.get_processor_name(),
			"cpu_cores": OS.get_processor_count(),
			"display_scale": DisplayServer.screen_get_scale(),
			"window_scale": ProjectSettings.get_setting("display/window/stretch/scale"),
			"content_scale": get_viewport().content_scale_factor,
			"window_mode": {
				DisplayServer.WINDOW_MODE_WINDOWED: "Windowed",
				DisplayServer.WINDOW_MODE_MINIMIZED: "Minimized",
				DisplayServer.WINDOW_MODE_MAXIMIZED: "Maximized",
				DisplayServer.WINDOW_MODE_FULLSCREEN: "Fullscreen",
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: "Exclusive Fullscreen",
			}.get(DisplayServer.window_get_mode(), "Unknown"),
			"window_count": DisplayServer.get_screen_count(),
			"window_size": str(DisplayServer.screen_get_size()),
			"viewport_size": str(Vector2i(
				ProjectSettings.get_setting("display/window/size/viewport_width"),
				ProjectSettings.get_setting("display/window/size/viewport_height"),
			)),
			"visible_viewport_size": str(Vector2i(get_viewport().get_visible_rect().size)),
		},
	}


func save_report(data: Dictionary, folder: String) -> void:
	var file := FileAccess.open(folder + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _on_bug_screenshot_mouse_exited() -> void:
	bug_screenshot_big_full_screen.hide()


func _on_bug_screenshot_mouse_entered() -> void:
	if include_screenshot_checkbox.button_pressed:
		bug_screenshot_big_full_screen.show()


func _on_include_screenshot_toggled(toggled_on: bool = include_screenshot_checkbox.button_pressed) -> void:
	bug_screenshot_preview.modulate.a = 1. if toggled_on else 0.3
	if not toggled_on:
		bug_screenshot_big_full_screen.hide()
