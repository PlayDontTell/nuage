extends Node2D

@onready var cursor_area: Area2D = %CursorArea


func _input(event: InputEvent) -> void:
	cursor_area.position = get_global_mouse_position()
