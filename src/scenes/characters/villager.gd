extends Node2D

@onready var legs_animation_player: AnimationPlayer = $LegsAnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	legs_animation_player.play("walk_right")



func _process(delta: float) -> void:
	position.x += delta * 55.
