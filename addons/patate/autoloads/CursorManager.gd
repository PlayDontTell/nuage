## Autoload. Manages hardware cursor appearance, visibility, and mouse mode.
##
## Cursors are defined in [CursorSet] and assigned via [member ProjectConfig.cursors].
## All slots are pre-uploaded to DisplayServer at startup, so switching cursors
## at runtime is instant — just a shape index change, no image transfer.
##
## [b]Stack:[/b] push_cursor/pop_cursor maintain an ordered stack. The topmost
## entry drives the active cursor. When the stack is empty, the default cursor
## from [member ProjectConfig.default_cursor_shape] is applied.
## Handles auto-release when their owning node leaves the scene tree.
##
## [b]Mouse mode:[/b] CursorManager is the sole caller of Input.set_mouse_mode.
## Use [method set_mouse_mode] instead of calling it directly.
##
## [b]Scale:[/b] cursor images are resized from cached originals using
## ui_scale × cursor_scale × screen_get_scale(). Re-uploaded automatically
## when ui_scale changes.
##
## [b]Platform:[/b] on platforms that do not support custom cursors
## (mobile, console), the system silently skips all cursor logic.
extends Node


## Opaque handle returned by [method push_cursor].
## Pass to [method pop_cursor] to restore the previous cursor.
## Auto-releases when the owning node leaves the scene tree.
var _supported := false
var _stack: Array[CursorHandle] = []
var _original_images: Dictionary = {}  # int (CursorShape) -> Image
var _cursor_hidden := false             # true when gamepad/touch active
var _mouse_mode := Input.MOUSE_MODE_VISIBLE  # game-requested mode


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_supported = DisplayServer.has_feature(DisplayServer.FEATURE_CUSTOM_CURSOR_SHAPE)
	if not _supported:
		push_warning("CursorManager: custom cursors not supported on this platform")
	DeviceManager.method_changed.connect(_on_method_changed)
	SettingsManager.setting_adjusted.connect(_on_setting_applied)


## Called by GameManager after SettingsManager.apply_settings().
## Caches original images, uploads all cursor slots at the correct scale,
## and applies the default cursor shape.
func initialize() -> void:
	_cache_original_images()
	_upload_all()
	_apply_top()


# ---- Public API ----

## Pushes [param shape] onto the cursor stack.
## The cursor immediately switches to [param shape].
## Returns a [CursorHandle] — pass it to [method pop_cursor] to restore
## the previous cursor. The handle auto-releases when [param node] exits
## the scene tree, so leaks are structurally impossible.
func push_cursor(shape: DisplayServer.CursorShape, node: Node) -> CursorHandle:
	var handle := CursorHandle.new()
	handle.shape = shape
	handle._node = node
	handle._auto_release_callable = func(): _pop_handle(handle)
	node.tree_exited.connect(handle._auto_release_callable)
	_stack.append(handle)
	_apply_top()
	return handle


## Removes [param handle] from the cursor stack.
## The cursor reverts to the next entry below, or to the default if the stack
## is now empty. Safe to call after the owning node has already been freed.
func pop_cursor(handle: CursorHandle) -> void:
	_pop_handle(handle)


## Re-applies the current top-of-stack cursor via a direct DisplayServer call.
## Use when a node disappears without mouse movement (e.g. destroyed mid-hover)
## and the cursor shape would otherwise not update until the mouse moves.
func refresh() -> void:
	_apply_top()


## Sets the mouse mode and makes CursorManager aware of it.
## [b]Always use this instead of calling Input.set_mouse_mode directly.[/b]
## CursorManager overrides the mode to MOUSE_MODE_HIDDEN when gamepad or
## touch is active, then restores [param mode] when the mouse returns.
func set_mouse_mode(mode: Input.MouseMode) -> void:
	_mouse_mode = mode
	_update_mouse_mode()


# ---- Internal ----

func _pop_handle(handle: CursorHandle) -> void:
	var idx := _stack.find(handle)
	if idx == -1:
		return
	if is_instance_valid(handle._node) \
	and handle._node.tree_exited.is_connected(handle._auto_release_callable):
		handle._node.tree_exited.disconnect(handle._auto_release_callable)
	_stack.remove_at(idx)
	# Clear the callable to break the circular reference:
	# handle._auto_release_callable captures handle → RefCounted cycle without this.
	handle._auto_release_callable = Callable()
	_apply_top()


func _apply_top() -> void:
	if _cursor_hidden or not _supported:
		return
	var shape: DisplayServer.CursorShape
	if _stack.is_empty():
		shape = G.config.default_cursor_shape if G.config else DisplayServer.CURSOR_ARROW
	else:
		shape = _stack.back().shape
	DisplayServer.cursor_set_shape(shape)


func _update_mouse_mode() -> void:
	if _cursor_hidden:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(_mouse_mode)
		_apply_top()


func _on_method_changed(method: DeviceManager.InputMethod) -> void:
	_cursor_hidden = method == DeviceManager.InputMethod.GAMEPAD \
		or method == DeviceManager.InputMethod.TOUCH
	_update_mouse_mode()


func _on_setting_applied(setting: String, _value: Variant) -> void:
	if setting == "ui_scale":
		_upload_all()


func _cache_original_images() -> void:
	if not G.config or not G.config.cursors:
		return
	# Cache the unscaled Image for each slot so _upload_all() always resizes
	# from the original — repeated scale changes never degrade quality.
	for i in DisplayServer.CURSOR_MAX:
		var data := G.config.cursors.get_for_shape(i)
		if data and data.texture:
			_original_images[i] = data.texture.get_image()


func _upload_all() -> void:
	if not _supported or not G.config or not G.config.cursors:
		return
	for i in DisplayServer.CURSOR_MAX:
		var data := G.config.cursors.get_for_shape(i)
		if data and data.texture:
			_upload_cursor(i, data)


func _upload_cursor(shape: int, data: CursorData) -> void:
	var original: Image = _original_images.get(shape)
	if not original:
		return
	var scale := _get_scale_factor()
	var target_size := max(1, int(round(data.base_size * scale)))
	var img := original.duplicate() as Image
	if img.get_width() != target_size:
		img.resize(target_size, target_size, data.interpolation)
	var scaled_hotspot := data.hotspot * (float(target_size) / float(data.base_size))
	DisplayServer.cursor_set_custom_image(
		ImageTexture.create_from_image(img),
		shape as DisplayServer.CursorShape,
		scaled_hotspot
	)


func _get_scale_factor() -> float:
	# ui_scale: user preference — cursor grows with the UI
	# cursor_scale: designer baseline multiplier from ProjectConfig
	# screen_get_scale: physical DPI factor (e.g. 2.0 on Retina displays)
	var ui_scale := SettingsManager.settings.ui_scale if SettingsManager.settings else 1.0
	var cursor_scale := G.config.cursor_scale if G.config else 1.0
	var screen_scale := DisplayServer.screen_get_scale()
	return ui_scale * cursor_scale * screen_scale
