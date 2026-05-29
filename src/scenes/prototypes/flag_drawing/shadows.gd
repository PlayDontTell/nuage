@tool
extends Polygon2D

const TWELF_FACTOR : float = 0.1
@export var color_gradient : GradientTexture1D
@export var lenght_curve : Curve


func _ready() -> void:
	# Await that day cacle var is set by parent
	await get_tree().process_frame
	set_shadow()


func get_length_at_twelf(current_day_time_ratio : float):
	return lenght_curve.sample(current_day_time_ratio)

func get_color_at_day_time(current_day_time_ratio : float):
	return color_gradient.gradient.sample(current_day_time_ratio)

func get_angle_at_day_time(event_day_twelf : int):
	return event_day_twelf * 360. / 12.


func set_shadow():
	set_angle(get_angle_at_day_time(9))
	set_colors(get_color_at_day_time(0.))


#func change_shadow(_current_twelf : int):
	#var current_day_time_ratio : float = Dim.get_day_time_ratio()
	#var current_day_twelf : int = Dim.get_day_twelf()
	#
	#if current_day_twelf == 0:
		#set_angle(-360. / 12.)
	#
	#
	#var tween = create_tween()
	#
	#tween.parallel().tween_method(
		#set_angle,
		#self.material.get_shader_parameter("angle"),
		#get_angle_at_day_time(current_day_twelf),
		#C.TWELF_DURATION * TWELF_FACTOR
	#).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#
	#if day_cycle:
		#tween.parallel().tween_method(
			#set_length,
			#self.material.get_shader_parameter("max_dist"),
			#get_length_at_twelf(current_day_time_ratio),
			#C.TWELF_DURATION * TWELF_FACTOR
		#).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		#
		#tween.parallel().tween_method(
			#set_colors,
			#self.material.get_shader_parameter("color"),
			#get_color_at_day_time(current_day_time_ratio),
			#C.TWELF_DURATION * TWELF_FACTOR
		#).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func set_length(new_length : float):
	self.material.set_shader_parameter("max_dist", new_length)


func set_angle(new_angle : float):
	self.material.set_shader_parameter("angle", new_angle)


func set_colors(new_color : Color):
	self.material.set_shader_parameter("color", new_color)
