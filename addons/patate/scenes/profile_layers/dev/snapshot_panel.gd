extends Control

@onready var category_input: LineEdit = %CategoryInput
@onready var name_input: LineEdit = %NameInput
@onready var description_input: TextEdit = %DescriptionInput
@onready var create_btn: Button = %CreateBtn
@onready var snapshot_list: VBoxContainer = %SnapshotList


func _ready() -> void:
	hide()


func open() -> void:
	PauseManager.request_pause(self, true)
	_rebuild_list()
	show()


func _on_close_btn_pressed() -> void:
	hide()
	PauseManager.request_pause(self, false)


func _on_create_btn_pressed() -> void:
	var category := category_input.text.strip_edges()
	var snapshot_name := name_input.text.strip_edges()
	var description := description_input.text.strip_edges()
	if not Utils.is_input_string_valid(category):
		Utils.flash_invalid(category_input)
		return
	if not Utils.is_input_string_valid(snapshot_name):
		Utils.flash_invalid(name_input)
		return
	SnapshotManager.save(category, snapshot_name, description)
	_rebuild_list()


func _rebuild_list() -> void:
	for child in snapshot_list.get_children():
		child.queue_free()

	var snapshots := SnapshotManager.list()
	if snapshots.is_empty():
		var empty := Label.new()
		empty.text = "SNAPSHOT_PANEL_EMPTY_TEXT"
		empty.modulate.a = 0.5
		snapshot_list.add_child(empty)
		return

	var current_category := ""
	for entry in snapshots:
		var data: Snapshot = entry.data
		var path: String = entry.path

		if data.category != current_category:
			current_category = data.category
			var cat_label: SnapshotCategory = preload("res://addons/patate/scenes/profile_layers/dev/snapshot_category_label.tscn").instantiate()
			snapshot_list.add_child(cat_label)
			cat_label.setup(current_category)

		var row: SnapshotRow = preload("res://addons/patate/scenes/profile_layers/dev/snapshot_row.tscn").instantiate()
		snapshot_list.add_child(row)
		row.setup(data, path)
		row.load_requested.connect(func(p):
			hide()
			PauseManager.request_pause(self, false)
			SnapshotManager.load_snapshot(p)
		)
		row.dupe_requested.connect(func(p):
			SnapshotManager.duplicate_snapshot(p)
			_rebuild_list()
		)
		row.delete_requested.connect(func(p):
			SnapshotManager.delete_snapshot(p)
			_rebuild_list()
		)
		row.rename_completed.connect(_rebuild_list)
	
	_on_category_input_text_changed()
	_on_label_input_text_changed()


func _on_category_input_text_changed(new_text: String = category_input.text) -> void:
	new_text = new_text.to_upper()
	var cursor : int = category_input.caret_column
	category_input.text = Utils.sanitize_string(new_text)
	category_input.caret_column = cursor

	var trimmed := category_input.text.strip_edges()
	var existing := SnapshotManager.list().map(func(e): return e.data.category.to_upper())
	
	if trimmed.is_empty():
		category_input.modulate = Color.WHITE
	elif trimmed in existing:
		category_input.modulate = SnapshotManager.category_color(trimmed)
	else:
		category_input.modulate = Color.WHITE


func _on_label_input_text_changed(new_text: String = name_input.text) -> void:
	var cursor : int = name_input.caret_column
	name_input.text = Utils.sanitize_string(new_text)
	name_input.caret_column = cursor
