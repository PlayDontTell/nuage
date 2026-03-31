extends CanvasLayer

@onready var critical_panel: Control = %CriticalPanel
@onready var timer_label: Label = %TimerLabel
@onready var press_any_key_label: Label = %PressAnyKeyLabel
@onready var kiosk_timer_disabled: Control = %ExpoKioskDisabled

## The index of the current expo event, from the list below (kiosk_events)
@export var active_event_index : int = 0

## The list of expo events the game is prepared to be presented at.
## Each Item contains all the info the game needs about the event and its configuration
## Including Game settings.
@export var kiosk_events : Array[KioskEventConfig] = []

@onready var current_event : KioskEventConfig = null

var kiosk_timer : float = 0.
var is_kiosk_timer_critical: bool = false
var is_booth_session_active: bool = false


func _ready() -> void:
	set_physics_process(false)

	init()


func _input(event: InputEvent) -> void:
	if InputManager.just_pressed_event("toggle_Kiosk_Keeper", event):
		set_kiosk_timer_enabled(not current_event.is_kiosk_timer_enabled)


func _physics_process(delta: float) -> void:
	var count_down: float = current_event.max_idle_time - kiosk_timer

	if count_down <= 9.9:
		timer_label.set_text(
			tr("KIOSK_TIMER_WARNING").format({"duration": Utils.round_to_dec(count_down, 1)})
		)
	else:
		timer_label.set_text(
			tr("KIOSK_TIMER_WARNING").format({"duration": int(count_down)})
		)

	var is_current_core_scene_an_exception : bool = G.core_scene in current_event.core_scene_exceptions
	if current_event.is_kiosk_timer_enabled and not is_current_core_scene_an_exception:
		if is_booth_session_active:
			kiosk_timer += delta

			if kiosk_timer > current_event.max_idle_time:
				G.request_game_restart.emit()
				reset_kiosk_timer()
				set_booth_active(false)

			elif kiosk_timer > current_event.critical_time and not is_kiosk_timer_critical:
				is_kiosk_timer_critical = true
				display_critical_panel(true)


func init() -> void:
	if not G.is_kiosk():
		self.queue_free()
		return

	if kiosk_events.is_empty():
		kiosk_events.append(KioskEventConfig.new())

	current_event = kiosk_events[active_event_index] if active_event_index < kiosk_events.size() else null

	if not current_event:
		push_error("KioskKeeper: no KioskEventConfig assigned.")
		self.queue_free()
		return

	# On every recognized input, consider the player is still playing
	# So reset kiosk timer, and declare booth active.
	DeviceManager.new_input.connect(reset_kiosk_timer)
	DeviceManager.new_input.connect(set_booth_active)

	set_physics_process(true)

	current_event.city_name = Utils.sanitize_string(current_event.city_name)
	current_event.event_name = Utils.sanitize_string(current_event.event_name)
	if current_event.game_settings:
		SettingsManager.apply_settings(current_event.game_settings)

	display_critical_panel(false)
	display_kiosk_timer_disabled(not current_event.is_kiosk_timer_enabled)


func apply_default_state() -> void:
	if current_event.snapshot:
		SnapshotManager.apply_snapshot(current_event.snapshot)
	else:
		if current_event.save_data:
			SaveManager.save_data = current_event.save_data.duplicate(true)
		G.request_core_scene.emit(G.config.kiosk_start_scene)


func get_archive_folder() -> String:
	return current_event.get_event_label()


var press_any_key_tween: Tween
func tween_press_any_key_label() -> void:
	if is_instance_valid(press_any_key_tween):
		press_any_key_tween.kill()
	press_any_key_tween = create_tween()

	press_any_key_tween.set_loops(int(INF))

	press_any_key_tween.tween_property(
		press_any_key_label,
		"modulate:a",
		0.25,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	press_any_key_tween.tween_property(
		press_any_key_label,
		"modulate:a",
		1.,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func display_kiosk_timer_disabled(request_display: bool) -> void:
	kiosk_timer_disabled.visible = request_display


var critical_panel_tween: Tween
func display_critical_panel(request_display: bool = true) -> void:
	critical_panel.visible = request_display

	if request_display:
		tween_press_any_key_label()

		if is_instance_valid(critical_panel_tween):
			critical_panel_tween.kill()
		critical_panel_tween = create_tween()

		critical_panel_tween.set_parallel(true)

		critical_panel_tween.tween_property(
			critical_panel,
			"modulate:a",
			1.,
			2.
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).from(0.)

		critical_panel_tween.tween_property(
			critical_panel,
			"scale",
			Vector2.ONE * 2.,
			current_event.max_idle_time - current_event.critical_time + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Vector2.ONE)

		critical_panel_tween.tween_property(
			timer_label,
			"modulate",
			Color.TOMATO,
			current_event.max_idle_time - current_event.critical_time + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Color.WHITE)

	else:
		if is_instance_valid(critical_panel_tween):
			critical_panel_tween.kill()


func reset_kiosk_timer() -> void:
	if is_instance_valid(press_any_key_tween):
		press_any_key_tween.kill()

	kiosk_timer = 0.
	if is_kiosk_timer_critical:
		is_kiosk_timer_critical = false
		display_critical_panel(false)


func set_booth_active(request_active: bool = true) -> void:
	if G.is_kiosk():
		is_booth_session_active = request_active and current_event.is_kiosk_timer_enabled
	else:
		is_booth_session_active = false


func set_kiosk_timer_enabled(request_enabled: bool = true) -> void:
	current_event.is_kiosk_timer_enabled = request_enabled
	display_kiosk_timer_disabled(not current_event.is_kiosk_timer_enabled)

	if not request_enabled:
		reset_kiosk_timer()
