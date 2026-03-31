class_name SnapshotCategory
extends MarginContainer

@onready var label: Label = %Label


func setup(category: String) -> void:
	label.text = category.to_upper()
	modulate = _category_color(category)


func _category_color(category: String) -> Color:
	var hue := (category.hash() & 0xFFFF) / 65535.0
	return Color.from_hsv(hue, 0.5, 0.9)
