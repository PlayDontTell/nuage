extends GameManager


func _setup_game() -> void:
	# Defining the Contexts (context: [actions])
	# List what Actions are allowed in this context.
	InputManager.extend_context(
		InputManager.Context.GAMEPLAY,
		[
			"interact",
		],
	)


func _reset_variables() -> void:
	pass
