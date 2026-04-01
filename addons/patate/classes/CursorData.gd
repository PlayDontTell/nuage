@tool
## A single cursor definition. Assign to a slot in [CursorSet] via [ProjectConfig].
class_name CursorData extends Resource

## Descriptive label for this cursor slot — e.g. "Attack", "Grab".
## Purely informational, never read at runtime.
@export var cursor_name: String = ""

## Optional notes on when this cursor is used.
## Purely informational, never read at runtime.
@export var cursor_description: String = ""

## The cursor texture. Leave empty to use the system default for this shape slot.
@export var texture: Texture2D

## The active point of the cursor image, in pixels at base scale (1×).
@export var hotspot: Vector2 = Vector2.ZERO

## Reference size of the texture in pixels at scale 1×.
## Used to compute the resized image when ui_scale or cursor_scale changes.
@export var base_size: int = 32

## Interpolation mode used when resizing the cursor image.
## Use INTERPOLATE_NEAREST for pixel art, INTERPOLATE_LANCZOS for smooth assets.
@export var interpolation: Image.Interpolation = Image.INTERPOLATE_NEAREST
