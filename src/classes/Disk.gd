@tool

class_name Disk
extends Polygon2D

@export var radius : float = 1. :
	set(v):
		radius = v
		_draw_circle()

@export var points_nbr : int = 8 :
	set(v):
		points_nbr = v
		_draw_circle()

@export var starting_angle : float = 0. :
	set(v):
		starting_angle = v
		_draw_circle()


func _draw_circle() -> void:
	polygon = Utils.generate_points_in_circle(
		Vector2.ZERO,
		radius,
		points_nbr,
		starting_angle
	)
