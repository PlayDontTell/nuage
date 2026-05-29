extends Node2D

@onready var mask: Sprite2D = $Mask

const GRASS_BLADE = preload("uid://yw0xp4aggnqr")

var grass_blades : int
var max_angle : float
var base_width : float
var base_length : float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.modulate = lerp(
		Color("50a62bff"),
		Color("32a655ff"),
		randf(),
	)
	
	grass_blades = randi_range(3, 5)
	
	max_angle = grass_blades * 12.
	base_width = grass_blades * 1.5
	base_length = randf_range(1.2, 1.8) * pow(grass_blades, 0.9)
	
	for i in range(grass_blades):
		var new_grass_blade : Line2D = GRASS_BLADE.instantiate()
		var base_point : Vector2 = Vector2(
				i * base_width / (grass_blades - 1) - base_width / 2.,
				0.
			)
		new_grass_blade.position = base_point
		new_grass_blade.add_point(Vector2.ZERO)
		new_grass_blade.add_point(
			Vector2.from_angle(
				deg_to_rad(i * max_angle / (grass_blades - 1) - max_angle / 2. - 90.)
			) * (base_length + randf() * base_length / 3. - 3 * pow(2 * (float(i) / float(grass_blades - 1)) - 1., 2.))
		)
		
		mask.add_child(new_grass_blade)


var time : float = randf_range(0., PI)
func _process(delta: float) -> void:
	time += delta
	mask.skew = sin(time) * 0.2
	mask.rotation_degrees = cos(time) * 0.5
