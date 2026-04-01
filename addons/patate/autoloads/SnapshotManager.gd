extends Node

const USER_DIR := "user://_snapshots/"
const RES_DIR := "res://_snapshots/"
const EXTENSION := ".snap.tres"


func _ready() -> void:
	if G.is_release():
		queue_free()
		return
	DirAccess.make_dir_recursive_absolute(USER_DIR)


func save(category: String, label: String, description: String) -> void:
	var snapshot := Snapshot.new()
	snapshot.category = category
	snapshot.label = label
	snapshot.description = description
	snapshot.core_scene = G.core_scene
	snapshot.created_at = Time.get_datetime_string_from_system()
	snapshot.save_data = SaveManager.save_data.duplicate(true)
	snapshot.save_data.save_image = null

	var path := USER_DIR + _build_filename(category, label, snapshot.created_at)
	var err := ResourceSaver.save(snapshot, path)
	if err != OK:
		push_error("SnapshotManager: failed to save — ", err)
	else:
		print("Snapshot saved: ", path)


func load_snapshot(path: String) -> void:
	var snapshot: Snapshot = ResourceLoader.load(path, "Snapshot", ResourceLoader.CACHE_MODE_IGNORE)
	if not snapshot:
		push_error("SnapshotManager: failed to load — ", path)
		return
	apply_snapshot(snapshot)


func apply_snapshot(snapshot: Snapshot) -> void:
	var migrated := SaveManager.update_save_data(snapshot.save_data.duplicate(true))
	SaveManager.save_data = migrated
	SaveManager.current_save_file_path = ""
	SaveManager.is_data_ready = true
	SaveManager.data_is_ready.emit()
	if snapshot.core_scene != &"":
		G.request_core_scene.emit(snapshot.core_scene)


func duplicate_snapshot(path: String) -> void:
	var snapshot: Snapshot = ResourceLoader.load(path, "Snapshot", ResourceLoader.CACHE_MODE_IGNORE)
	if not snapshot:
		push_error("SnapshotManager: failed to load for duplication — ", path)
		return

	var dupe: Snapshot = snapshot.duplicate(true)
	dupe.created_at = Time.get_datetime_string_from_system()
	dupe.save_data.save_image = null

	var base : String = dupe.label
	# strip existing _copy_N suffix
	var regex : RegEx = RegEx.new()
	regex.compile("^(.+?)(_copy(_\\d+)?)?$")
	var result := regex.search(dupe.label)
	base = result.get_string(1) if result else dupe.label

	var existing : Array = list().map(func(e): return e.data.label)
	var candidate : String = base + "_copy"
	var n : int = 2
	while candidate in existing:
		candidate = base + "_copy_" + str(n)
		n += 1
	dupe.label = candidate

	var new_path := USER_DIR + _build_filename(dupe.category, dupe.label, dupe.created_at)
	var err := ResourceSaver.save(dupe, new_path)
	if err != OK:
		push_error("SnapshotManager: failed to save duplicate — ", err)


func delete_snapshot(path: String) -> void:
	if not path.begins_with(USER_DIR):
		push_error("SnapshotManager: cannot delete res:// snapshots — ", path)
		return
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("SnapshotManager: failed to delete — ", err)


func list() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for path in _scan_dir(USER_DIR) + _scan_dir(RES_DIR):
		var snapshot: Snapshot = ResourceLoader.load(path, "Snapshot", ResourceLoader.CACHE_MODE_IGNORE)
		if snapshot:
			results.append({"path": path, "data": snapshot})
	results.sort_custom(func(a, b):
		if a.data.category != b.data.category:
			return a.data.category < b.data.category
		return a.data.created_at < b.data.created_at
	)
	return results


func _build_filename(category: String, label: String, timestamp: String) -> String:
	var safe_ts := timestamp.replace(":", "-")
	var safe_cat := category.to_upper().replace(" ", "_")
	var safe_label := label.replace(" ", "_")
	return "(%s)_%s_(%s)%s" % [safe_cat, safe_label, safe_ts, EXTENSION]


func _scan_dir(dir_path: String) -> Array[String]:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return []
	var paths: Array[String] = []
	for file in dir.get_files():
		if file.ends_with(EXTENSION):
			paths.append(dir_path + file)
	return paths


func category_color(category: String) -> Color:
	var hue := (category.hash() & 0xFFFF) / 65535.0
	return Color.from_hsv(hue, 0.5, 0.9)


func rename_snapshot(path: String, new_label: String, new_category: String, new_description: String) -> void:
	var snapshot: Snapshot = ResourceLoader.load(path, "Snapshot", ResourceLoader.CACHE_MODE_IGNORE)
	if not snapshot:
		push_error("SnapshotManager: failed to load for rename — ", path)
		return
	snapshot.label = new_label
	snapshot.category = new_category
	snapshot.description = new_description
	var new_path : String = USER_DIR + _build_filename(new_category, new_label, snapshot.created_at)
	var err := ResourceSaver.save(snapshot, new_path)
	if err != OK:
		push_error("SnapshotManager: failed to save renamed snapshot — ", err)
		return
	if path != new_path:
		delete_snapshot(path)
