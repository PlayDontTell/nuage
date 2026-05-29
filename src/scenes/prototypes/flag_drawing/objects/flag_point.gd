class_name FlagPoint
extends Area2D

@onready var hook_zone: Line2D = %HookZone
@onready var connection_point: Polygon2D = %ConnectionPoint
@onready var flag_link: Line2D = %FlagLink

enum State {
	FREE,
	PLACED_UNCONNECTABLE,
	PLACED_CONNECTABLE,
	PLACED_CONNECTED,
}

var index : int = 0
var previous_flag_point : FlagPoint = null
var state : State = State.FREE



func _ready() -> void:
	init_visuals()
	change_state(FlagPoint.State.FREE)


func init_visuals() -> void:
	for object in [
		connection_point,
		hook_zone,
	]:
		object.scale = Vector2.ZERO
		object.modulate.a = 0.
	
	connection_point.set_polygon(
		Utils.generate_points_in_circle(
			Vector2.ZERO,
			3.,
			14
		)
	)
	hook_zone.set_points(
		Utils.generate_points_in_circle(
			Vector2.ZERO,
			6.,
			20
		)
	)
	if index != 0:
		flag_link.add_point(Vector2.ZERO)
		flag_link.add_point(Vector2.ZERO)


func move(new_position : Vector2) -> void:
	position = new_position
	set_flag_link()


func set_flag_link() -> void:
	if previous_flag_point != null:
		var line_direction : Vector2 = (position - previous_flag_point.position).normalized()
		
		if state in [
			State.FREE,
			State.PLACED_UNCONNECTABLE,
		]:
			flag_link.set_point_position(0, Vector2.ZERO)
		else:
			flag_link.set_point_position(0, -line_direction * 6)
		
		if previous_flag_point.state in [
			State.FREE,
			State.PLACED_UNCONNECTABLE,
		]:
			flag_link.set_point_position(1, (previous_flag_point.position - position))
		else:
			flag_link.set_point_position(1, (previous_flag_point.position - position) + line_direction * 6)


func change_state(new_state : State) -> void:
	var old_state : State = state
	state = new_state
	
	connection_point.self_modulate.a = 1.
	
	match state:
		State.FREE:
			enable_objects([connection_point], [hook_zone])
		
		State.PLACED_UNCONNECTABLE:
			enable_objects([connection_point], [hook_zone])
			await get_tree().process_frame
		
		State.PLACED_CONNECTABLE:
			enable_objects([hook_zone], [connection_point])
			await get_tree().process_frame
		
		State.PLACED_CONNECTED:
			enable_objects([hook_zone, connection_point], [])
			await get_tree().process_frame
	
	if not state == State.FREE:
		set_flag_link()


var _object_enable_tween : Tween
func enable_objects(objects_to_enable : Array[Node], objects_to_disable : Array[Node]) -> void:
	if is_instance_valid(_object_enable_tween):
		_object_enable_tween.kill()
	_object_enable_tween = create_tween()
	_object_enable_tween.set_parallel(true)
	
	for object in objects_to_enable:
		if not is_instance_valid(object):
			continue
		
		_object_enable_tween.tween_property(
			object,
			"scale",
			Vector2(1., 0.75),
			1.
		).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		_object_enable_tween.tween_property(
			object,
			"modulate:a",
			1.,
			0.3
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	
	for object in objects_to_disable:
		if not is_instance_valid(object):
			continue
		
		_object_enable_tween.tween_property(
			object,
			"scale",
			Vector2.ZERO,
			1.
		).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		_object_enable_tween.tween_property(
			object,
			"modulate:a",
			0.,
			1.
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
