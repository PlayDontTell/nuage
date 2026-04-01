## Drop-in child node that automatically changes the cursor when the mouse
## enters or exits the parent node.
##
## Behaviour differs by parent type:[br]
## - [Control]: sets [member Control.mouse_default_cursor_shape] directly.
##   Godot's built-in hover system applies it — no push/pop stack involved.[br]
## - [Area2D], [Area3D], [CollisionObject2D], [CollisionObject3D] and any other
##   node with [signal mouse_entered]/[signal mouse_exited]: uses
##   [CursorManager.push_cursor] and [CursorManager.pop_cursor].
##
## [b]Known limitations:[/b][br]
## - Switching from gamepad back to mouse while hovering a non-Control parent
##   will not restore the hover cursor until the mouse moves.[br]
## - Adding CursorRegion dynamically to an already-hovered node will not
##   push the cursor until the next mouse_entered event.[br]
## - Area2D/3D parents require [member CollisionObject2D.input_pickable] = true
##   and a CollisionShape to emit mouse signals.
class_name CursorRegion extends Node

## The cursor shape to apply when the mouse is over the parent node.
## For Control parents, updating this at runtime immediately updates
## [member Control.mouse_default_cursor_shape].
@export var cursor_shape: DisplayServer.CursorShape = DisplayServer.CURSOR_POINTING_HAND:
	set(value):
		cursor_shape = value
		if is_inside_tree() and get_parent() is Control:
			get_parent().mouse_default_cursor_shape = value

var _handle: CursorHandle


func _ready() -> void:
	var parent := get_parent()

	if parent is Control:
		if parent.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			push_warning("CursorRegion: parent '%s' has MOUSE_FILTER_IGNORE — signals will not fire" % parent.name)
			return
		parent.mouse_default_cursor_shape = cursor_shape
			# When the Control is destroyed mid-hover, force an immediate cursor
			# reset — Godot only re-queries cursor shape on mouse movement.
		parent.tree_exiting.connect(CursorManager.refresh)
		return

	if not parent.has_signal("mouse_entered") or not parent.has_signal("mouse_exited"):
		push_warning("CursorRegion: parent '%s' has no mouse_entered/mouse_exited signals" % parent.name)
		return

	parent.mouse_entered.connect(_on_mouse_entered)
	parent.mouse_exited.connect(_on_mouse_exited)
	DeviceManager.method_changed.connect(_on_method_changed)


func _on_mouse_entered() -> void:
	if _handle:
		CursorManager.pop_cursor(_handle)
	_handle = CursorManager.push_cursor(cursor_shape, self)


func _on_mouse_exited() -> void:
	if _handle:
		CursorManager.pop_cursor(_handle)
		_handle = null


func _on_method_changed(method: DeviceManager.InputMethod) -> void:
	# Pop the handle when switching to a non-cursor input method, so the
	# stack does not accumulate stale entries while the cursor is hidden.
	if method == DeviceManager.InputMethod.GAMEPAD \
	or method == DeviceManager.InputMethod.TOUCH:
		if _handle:
			CursorManager.pop_cursor(_handle)
			_handle = null
