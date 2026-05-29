@tool
extends Polygon2D

const GRASS_PATCH = preload("uid://dedsk0l436bgu")

@export var corner_radius: int = 16:
	set(value):
		corner_radius = value
		_on_polygon_changed()

@export var gradient: GradientTexture1D = GradientTexture1D.new()

@export var height : float = 16.:
	set(value):
		height = value
		_on_polygon_changed()

@onready var border_bottom: RoundedPolygon2D = $BorderBottom
@onready var layer_1: RoundedPolygon2D = $Layer1
@onready var layer_2: RoundedPolygon2D = $Layer2
@onready var layer_3: RoundedPolygon2D = $Layer3
@onready var border_top: RoundedPolygon2D = $BorderTop
@onready var layer_4: RoundedPolygon2D = $Layer4
@onready var shadow: Polygon2D = $Shadow
#@onready var wall_shadow: Polygon2D = $WallShadow


func _ready() -> void:
	self.modulate.a = 0.
	await redraw()
	init_animation()


func _set(property: StringName, value: Variant) -> bool:
	if property == "polygon":
		polygon = value
		_on_polygon_changed()
		return true
	return false


func _on_polygon_changed():
	if Engine.is_editor_hint():
		redraw()


func redraw() -> void:
	var layers : Array = [
		layer_1,
		layer_2,
		layer_3,
		layer_4,
	]
	for i in range(layers.size()):
		layers[i].polygon = polygon
		layers[i].position.y = - height * i / (layers.size() - 1)
		layers[i].color = gradient.gradient.sample(float(i) / float(layers.size() - 1))
		layers[i].corner_radius = corner_radius
	
	
	border_top.polygon = polygon
	border_top.position.y = -height - 1.
	border_top.color = Color(0.145, 0.357, 0.118, 1.0)
	border_top.corner_radius = corner_radius * 0.9375
	
	
	border_bottom.polygon = polygon
	border_bottom.position.y = 1.0
	border_bottom.color = Color(0.145, 0.357, 0.118, 1.0)
	border_bottom.corner_radius = corner_radius * 0.9375
	
	await get_tree().process_frame
	for top_polygon in Geometry2D.offset_polygon(polygon, -1.5, Geometry2D.JOIN_MITER):
		var new_top_polygon : RoundedPolygon2D = RoundedPolygon2D.new()
		
		new_top_polygon.draw.emit()
		
		new_top_polygon.polygon = top_polygon
		new_top_polygon.position.y = -height
		new_top_polygon.color = Color("00913aff")
		new_top_polygon.corner_radius = corner_radius
		new_top_polygon.z_index = 4
		
		self.add_child(new_top_polygon)
		
		var grass_zones : Array[PackedVector2Array] = Geometry2D.offset_polygon(polygon, -2., Geometry2D.JOIN_MITER)

		#for i in range(int(Triangle.get_polygon_area(grass_zone) / 1000.)):
			#var new_grass_patch = GRASS_PATCH.instantiate()
			#new_grass_patch.position = Triangle.get_random_point_in_polygon(grass_zone)
			#new_grass_patch.z_index = 4
			#top.add_child(new_grass_patch)

		for grass_zone in grass_zones:
			var grass_patches : Array[Vector2] = get_cells_in_polygon(
				grass_zone,
				Vector2.ZERO,
				Global.CELL
			)
			
			for grass_patch_position in grass_patches:
				if randf() > 0.4:
					continue
				
				var new_grass_patch = GRASS_PATCH.instantiate()
				new_grass_patch.position = grass_patch_position + Vector2(
					randf_range(-1., 1.) * Global.CELL.x * 0.2,
					randf_range(-1., 1.) * Global.CELL.y * 0.2,
				)
				new_grass_patch.z_index = 4
				new_top_polygon.add_child(new_grass_patch)
	
	shadow.polygon = layer_1.rounded_polygon
	
	#get_wall_shadow_polygons(
		#layer_1.rounded_polygon,
		#shadow.offset,
		#deg_to_rad(15.),
		#32.,
		#wall_shadow
	#)
	return


func merge_polygons(polygons_array : Array) -> PackedVector2Array:
	var final_polygon : PackedVector2Array = polygons_array[0]
	for i in range(polygons_array.size() - 1):
		final_polygon = Geometry2D.merge_polygons(
			final_polygon,
			polygons_array[i + 1],
		)[0]
	return final_polygon


func shadow_polygon(polygon: PackedVector2Array, offset: Vector2) -> Array:
	var offset_poly := PackedVector2Array()
	for point in polygon:
		offset_poly.append(point + offset)
	
	# merge_polygons returns an Array of PackedVector2Array (can be multiple if disjoint)
	return Geometry2D.merge_polygons(polygon, offset_poly)



func get_wall_shadow_polygons(
	poly: PackedVector2Array,
	direction: Vector2,
	angle_tolerance: float,
	height: float,
	wall_shadow_node: Polygon2D
) -> void:
	if poly.size() < 2:
		wall_shadow_node.polygons = []
		wall_shadow_node.polygon = PackedVector2Array()
		return

	var dir := direction.normalized()
	var all_verts := PackedVector2Array()
	var all_polys : Array[PackedInt32Array] = []

	var accepted : Array[int] = []
	for i in range(poly.size()):
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var seg_dir := (b - a).normalized()
		var normal := Vector2(-seg_dir.y, seg_dir.x)

		if normal.dot(dir) >= 0.0:
			continue
		if abs(seg_dir.dot(dir)) > sin(angle_tolerance):
			continue
		accepted.append(i)

	if accepted.is_empty():
		wall_shadow_node.polygons = []
		wall_shadow_node.polygon = PackedVector2Array()
		return

	# Group consecutive indices into runs
	var runs : Array = []
	var current_run : Array[int] = [accepted[0]]
	for i in range(1, accepted.size()):
		if accepted[i] == accepted[i - 1] + 1:
			current_run.append(accepted[i])
		else:
			runs.append(current_run)
			current_run = [accepted[i]]
	runs.append(current_run)

	for run in runs:
		var base := all_verts.size()

		# Bottom edge forward
		for idx in run:
			all_verts.append(poly[idx])
		# Last point of the run's final segment
		all_verts.append(poly[(run[-1] + 1) % poly.size()])

		# Top edge reversed (keeps CCW winding)
		all_verts.append(poly[(run[-1] + 1) % poly.size()] + dir * height)
		for i in range(run.size() - 1, -1, -1):
			all_verts.append(poly[run[i]] + dir * height)

		# Index range for this strip
		var count :int = run.size() + 1  # number of bottom verts
		var indices := PackedInt32Array()
		for j in range(count * 2):
			indices.append(base + j)
		all_polys.append(indices)

	# Always clear polygons BEFORE changing polygon to avoid stale index errors
	wall_shadow_node.polygons = []
	wall_shadow_node.polygon = all_verts
	wall_shadow_node.polygons = all_polys


var _tween : Tween
func init_animation():
	_tween = create_tween()
	_tween.set_parallel(true)
	
	_tween.tween_property(
		self,
		"modulate:a",
		1.,
		0.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	for layer in self.get_children():
		if not layer in [
			shadow,
			border_bottom,
			layer_1,
		]:
			_tween.tween_property(
				layer,
				"position:y",
				layer.position.y,
				1.
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).from(0.)


static func get_cells_in_polygon(
	polygon: PackedVector2Array,
	polygon_position: Vector2,
	cell_size: Vector2
) -> Array[Vector2]:
	var cells: Array[Vector2] = []
	if polygon.size() < 3:
		return cells
	
	# Compute world-space bounding box
	var min_pt := polygon[0] + polygon_position
	var max_pt := min_pt
	for p in polygon:
		var world_p := p + polygon_position
		min_pt = min_pt.min(world_p)
		max_pt = max_pt.max(world_p)
	
	# Snap to grid indices that overlap the bounding box
	var start_x := floori(min_pt.x / cell_size.x)
	var start_y := floori(min_pt.y / cell_size.y)
	var end_x := ceili(max_pt.x / cell_size.x)
	var end_y := ceili(max_pt.y / cell_size.y)
	
	# Test each candidate cell's center against the polygon
	for gx in range(start_x, end_x):
		for gy in range(start_y, end_y):
			var cell_center := Vector2(
				(gx + 0.5) * cell_size.x,
				(gy + 0.5) * cell_size.y
			)
			# Polygon points are in local space, so subtract its position
			if Geometry2D.is_point_in_polygon(cell_center - polygon_position, polygon):
				cells.append(cell_center)
	
	return cells
