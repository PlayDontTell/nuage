@tool
## Maps all 17 DisplayServer cursor shape slots to [CursorData] resources.
## Assign a CursorSet instance to [member ProjectConfig.cursors] in the inspector.
##
## Each property corresponds to one [enum DisplayServer.CursorShape] slot.
## CursorManager pre-uploads all non-null slots at startup, so switching
## between cursors at runtime is instant (no image transfer).
##
## Game-specific cursors reuse shape slots — e.g. assign a sword texture to
## [member cross] and push CURSOR_CROSS when the player hovers an enemy.
## Leave slots null to fall back to the system default for that shape.
class_name CursorSet extends Resource

@export var arrow: CursorData
@export var ibeam: CursorData
@export var pointing_hand: CursorData
@export var cross: CursorData
@export var wait: CursorData
@export var busy: CursorData
@export var drag: CursorData
@export var can_drop: CursorData
@export var forbidden: CursorData
@export var vsize: CursorData
@export var hsize: CursorData
@export var bdiagsize: CursorData
@export var fdiagsize: CursorData
@export var move: CursorData
@export var vsplit: CursorData
@export var hsplit: CursorData
@export var help: CursorData


## Returns the [CursorData] assigned to [param shape], or null if the slot is empty.
func get_for_shape(shape: DisplayServer.CursorShape) -> CursorData:
	match shape:
		DisplayServer.CURSOR_ARROW:         return arrow
		DisplayServer.CURSOR_IBEAM:         return ibeam
		DisplayServer.CURSOR_POINTING_HAND: return pointing_hand
		DisplayServer.CURSOR_CROSS:         return cross
		DisplayServer.CURSOR_WAIT:          return wait
		DisplayServer.CURSOR_BUSY:          return busy
		DisplayServer.CURSOR_DRAG:          return drag
		DisplayServer.CURSOR_CAN_DROP:      return can_drop
		DisplayServer.CURSOR_FORBIDDEN:     return forbidden
		DisplayServer.CURSOR_VSIZE:         return vsize
		DisplayServer.CURSOR_HSIZE:         return hsize
		DisplayServer.CURSOR_BDIAGSIZE:     return bdiagsize
		DisplayServer.CURSOR_FDIAGSIZE:     return fdiagsize
		DisplayServer.CURSOR_MOVE:          return move
		DisplayServer.CURSOR_VSPLIT:        return vsplit
		DisplayServer.CURSOR_HSPLIT:        return hsplit
		DisplayServer.CURSOR_HELP:          return help
	return null
