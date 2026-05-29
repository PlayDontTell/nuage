class_name Triangle

var _p1 : Vector2
var _p2 : Vector2
var _p3 : Vector2

func _init(p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	_p1 = p1
	_p2 = p2
	_p3 = p3

func get_triangle_area() -> float:
	return 0.5 * abs((_p1.x*(_p2.y - _p3.y)) + (_p2.x*(_p3.y - _p1.y)) + (_p3.x*(_p1.y - _p2.y)))

func get_random_point():
	var a = randf()
	var b = randf()
	if a > b:
		var c = b
		b = a
		a = c

	return _p1 * a + _p2 * (b - a) + _p3 * (1 - b)

static func get_random_point_in_polygon(polygon: PackedVector2Array) -> Vector2:
	return get_random_point_in_triangulated_polygon(polygon, Geometry2D.triangulate_polygon(polygon))

static func get_random_point_in_triangulated_polygon(polygon: PackedVector2Array, triangle_points : PackedInt32Array) -> Vector2:
	var triangle_weights : PackedFloat32Array = []
	var triangles : Array[Triangle] = []
	
	var index = 0
	var polygon_size = triangle_points.size()
	while index < polygon_size:
		var triangle = Triangle.new(polygon[triangle_points[index]], polygon[triangle_points[index + 1]], polygon[triangle_points[index + 2]])
		triangles.append(triangle)
		triangle_weights.append(triangle.get_triangle_area())
		index += 3
	
	## TODO: We should allow the consumer to specify their own source of randomness, if desired.
	return triangles[RandomNumberGenerator.new().rand_weighted(triangle_weights)].get_random_point()

static func get_polygon_area(polygon: PackedVector2Array) -> float:
	var n := polygon.size()
	if n < 3:
		return 0.0
	
	var area := 0.0
	for i in n:
		var current := polygon[i]
		var next := polygon[(i + 1) % n]
		area += current.x * next.y - next.x * current.y
	
	return absf(area) * 0.5
