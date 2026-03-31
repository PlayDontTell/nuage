class_name SnapshotRow
extends PanelContainer

signal load_requested(path: String)
signal dupe_requested(path: String)
signal delete_requested(path: String)
signal rename_completed

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var source_label: Label = %SourceLabel
@onready var info: VBoxContainer = %Info
@onready var load_btn: Button = %LoadBtn
@onready var dupe_btn: Button = %DupeBtn
@onready var del_btn: Button = %DelBtn

@onready var default_controls: HBoxContainer = %DefaultControls
@onready var rename_controls: HBoxContainer = %RenameControls
@onready var old_label_display: Label = %OldLabelDisplay
@onready var new_label_input: LineEdit = %NewLabelInput
@onready var old_category_display: Label = %OldCategoryDisplay
@onready var new_category_input: LineEdit = %NewCategoryInput
@onready var rename_btn: Button = %RenameBtn

var _path: String
var _data: SnapshotData


func _ready() -> void:
	rename_controls.hide()


func setup(data: SnapshotData, path: String) -> void:
	_data = data
	_path = path

	title_label.text = data.label
	subtitle_label.text = "%s  •  %s" % [data.core_scene, data.created_at]

	var is_shipped := path.begins_with("res://")
	source_label.text = "SNAPSHOT_PANEL_SHARED_LABEL" if is_shipped else "SNAPSHOT_PANEL_LOCAL_LABEL"
	source_label.modulate = Color(0.4, 0.8, 0.4) if is_shipped else Color(0.6, 0.6, 0.6)

	del_btn.disabled = is_shipped
	rename_btn.disabled = is_shipped
	del_btn.modulate.a = 0.4 if is_shipped else 1.0
	rename_btn.modulate.a = 0.4 if is_shipped else 1.0

	var tint : Color = SnapshotManager.category_color(data.category)
	tint.a = 0.06
	self.self_modulate = tint


func _on_load_btn_pressed() -> void:
	load_requested.emit(_path)

func _on_dupe_btn_pressed() -> void:
	dupe_requested.emit(_path)

func _on_del_btn_pressed() -> void:
	delete_requested.emit(_path)


func _on_rename_btn_pressed() -> void:
	old_label_display.text = _data.label
	new_label_input.text = _data.label
	old_category_display.text = _data.category
	new_category_input.text = _data.category
	default_controls.hide()
	info.hide()
	source_label.hide()
	rename_controls.show()
	_on_new_category_input_text_changed()
	_on_new_label_input_text_changed()


func _on_cancel_rename_btn_pressed() -> void:
	rename_controls.hide()
	default_controls.show()
	source_label.show()
	info.show()


func _on_confirm_rename_btn_pressed() -> void:
	var new_label := new_label_input.text.strip_edges()
	var new_category := new_category_input.text.strip_edges()
	if not Utils.is_input_string_valid(new_label):
		Utils.flash_invalid(new_label_input)
		return
	if not Utils.is_input_string_valid(new_category):
		Utils.flash_invalid(new_category_input)
		return
	SnapshotManager.rename_snapshot(_path, new_label, new_category)
	rename_completed.emit()


func _on_new_category_input_text_changed(new_text: String = new_category_input.text) -> void:
	var cursor := new_category_input.caret_column
	new_category_input.text = Utils.sanitize_string(new_text)
	new_category_input.caret_column = cursor

	var trimmed := new_category_input.text.strip_edges()
	var existing := SnapshotManager.list().map(func(e): return e.data.category)
	if trimmed.is_empty():
		new_category_input.modulate = Color.WHITE
	elif trimmed in existing:
		new_category_input.modulate = SnapshotManager.category_color(trimmed)
	else:
		new_category_input.modulate = Color.WHITE


func _on_new_label_input_text_changed(new_text: String = new_label_input.text) -> void:
	var cursor := new_label_input.caret_column
	new_label_input.text = Utils.sanitize_string(new_text)
	new_label_input.caret_column = cursor
