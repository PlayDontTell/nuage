extends Node2D

const FLAG_POINT = preload("uid://wsttfkfagcvb")
const WALL_POLYGON = preload("uid://ck1ny1tusvsyj")

var flag_points : Array[FlagPoint] = []
var hovered_flag_points : Array[FlagPoint] = []
var flags_ready : bool = false


func _ready() -> void:
	reset_drawing()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		move_current_flag_point()


func _process(delta: float) -> void:
	if InputManager.just_pressed("place_flag"):
		place_current_flag_point()
	
	if InputManager.just_pressed("reset_flags"):
		reset_drawing()


func move_current_flag_point() -> void:
	if flags_ready:
		pass
	elif hovered_flag_points.size() > 0:
		flag_points[-1].move(hovered_flag_points[-1].position)
	else:
		flag_points[-1].move(
			get_global_mouse_position()
			#get_global_mouse_position().snapped(
				#Global.CELL
			#)
		)


func place_current_flag_point() -> void:
	flag_points[0].change_state(FlagPoint.State.PLACED_UNCONNECTABLE)
	flag_points[-1].change_state(FlagPoint.State.PLACED_CONNECTABLE)
	
	if flag_points.size() > 2:
		flag_points[-2].change_state(FlagPoint.State.PLACED_UNCONNECTABLE)
		flag_points[0].change_state(FlagPoint.State.PLACED_CONNECTABLE)
	
	if hovered_flag_points.size() > 0:
		flag_points[-1].change_state(FlagPoint.State.PLACED_CONNECTED)
		flags_ready = true
		
		var points = get_current_points()
		
		var is_polygon_closed : bool = hovered_flag_points.size() > 0 and hovered_flag_points[-1] == flag_points[0]
		var polygon_to_draw : PackedVector2Array = points
		
		var clean_polygons: Array[PackedVector2Array]
		
		if points.size() == 1:
			polygon_to_draw = Utils.generate_points_in_circle(
				points[0],
				Global.CELL.x / 2.,
				10,
				0.,
				Global.CELL.x / Global.CELL.y,
			)
			clean_polygons = [polygon_to_draw]
		else:
			if not is_polygon_closed:
				#polygon_to_draw = Geometry2D.offset_polyline(polygon_to_draw, 8.)[0]
				polygon_to_draw = offset_polyline_anisotropic(polygon_to_draw, Global.CELL * 0.5)[0]
				clean_polygons = [polygon_to_draw]
			else:
				clean_polygons = Geometry2D.merge_polygons(polygon_to_draw, polygon_to_draw)
		
		for clean_polygon in clean_polygons:
			clean_polygon = ensure_clockwise(clean_polygon)
			
			var new_hill = WALL_POLYGON.instantiate()
			new_hill.polygon = clean_polygon
			$"../Hills".add_child(new_hill)
			reset_drawing()
	else:
		add_flag_point()
		flag_points[-1].previous_flag_point = flag_points[-2]


func add_flag_point() -> void:
	var new_flag_point = FLAG_POINT.instantiate()
	new_flag_point.index = flag_points.size()
	self.add_child(new_flag_point)
	flag_points.append(new_flag_point)
	if flag_points.size() > 1:
		move_current_flag_point()
		hovered_flag_points.append(new_flag_point)
			


func get_current_points() -> PackedVector2Array:
	var points : PackedVector2Array = []
	
	for flag_point in flag_points:
		if not flag_point.position in points:
			points.append(flag_point.position)
	
	return points


func _on_cursor_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("flag_point"):
		var flag_point : FlagPoint = area
		if not flag_point in hovered_flag_points:
			if flag_point.state == FlagPoint.State.PLACED_CONNECTABLE:
				hovered_flag_points.append(flag_point)


func _on_cursor_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("flag_point"):
		var flag_point : FlagPoint = area
		if flag_point in hovered_flag_points:
			hovered_flag_points.erase(flag_point)


func ensure_clockwise(_polygon: PackedVector2Array) -> PackedVector2Array:
	if signed_area(_polygon) < 0.0:
		_polygon.reverse()
	return _polygon

func signed_area(_polygon: PackedVector2Array) -> float:
	var area := 0.0
	var n := _polygon.size()
	for i in n:
		var a := _polygon[i]
		var b := _polygon[(i + 1) % n]
		area += (b.x - a.x) * (b.y + a.y)
	return area * 0.5


func reset_drawing() -> void:
	for flag_point in self.get_children():
		flag_point.queue_free()
	flag_points.clear()
	hovered_flag_points.clear()
	add_flag_point()
	flags_ready = false
	move_current_flag_point()


static func offset_polyline_anisotropic(
	polyline: PackedVector2Array,
	offset: Vector2,
	join_type: int = Geometry2D.JOIN_SQUARE,
	end_type: int = Geometry2D.END_SQUARE
) -> Array[PackedVector2Array]:
	if offset.x <= 0.0 or offset.y <= 0.0:
		return []
	
	# Pick a uniform offset (the larger axis), then derive a scale
	# that turns it into the desired per-axis offsets after unscaling.
	var uniform_offset := maxf(offset.x, offset.y)
	var scale := Vector2(uniform_offset / offset.x, uniform_offset / offset.y)
	
	# Scale the polyline up
	var scaled := PackedVector2Array()
	scaled.resize(polyline.size())
	for i in polyline.size():
		scaled[i] = polyline[i] * scale
	
	# Uniform offset in scaled space
	var offset_polygons := Geometry2D.offset_polyline(scaled, uniform_offset, join_type, end_type)
	
	# Unscale the results
	var inv_scale := Vector2(1.0 / scale.x, 1.0 / scale.y)
	var result: Array[PackedVector2Array] = []
	for poly in offset_polygons:
		var unscaled := PackedVector2Array()
		unscaled.resize(poly.size())
		for i in poly.size():
			unscaled[i] = poly[i] * inv_scale
		result.append(unscaled)
	
	return result


func _on_reset_btn_pressed() -> void:
	reset_drawing()
	for child in $"../Hills".get_children():
		child.queue_free()
