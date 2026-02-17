extends CanvasLayer
## Touch control overlay for mobile. Auto-hides on desktop.
## Virtual joystick (left), camera drag (right), action buttons.

@export var joystick_deadzone: float = 0.15
@export var camera_sensitivity: float = 0.003

var _joystick_active: bool = false
var _joystick_touch_index: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_vector: Vector2 = Vector2.ZERO
var _camera_touch_index: int = -1
var _camera_last_pos: Vector2 = Vector2.ZERO
var _is_mobile: bool = false

@onready var _joystick_base: Control = $JoystickBase
@onready var _joystick_knob: Control = $JoystickBase/JoystickKnob
@onready var _jump_btn: Button = $JumpButton
@onready var _interact_btn: Button = $InteractButton
@onready var _menu_btn: Button = $MenuButton

func _ready() -> void:
	_is_mobile = OS.has_feature("mobile") or OS.has_feature("web")
	if not _is_mobile:
		visible = false
		set_process(false)
		set_process_input(false)
		DebugLog.log("TouchControls", "desktop detected — touch controls hidden")
		return

	DebugLog.log("TouchControls", "mobile detected — touch controls active")
	_jump_btn.pressed.connect(_on_jump_pressed)
	_interact_btn.pressed.connect(_on_interact_pressed)
	_menu_btn.pressed.connect(_on_menu_pressed)

func _input(event: InputEvent) -> void:
	if not _is_mobile:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var screen_half: float = get_viewport().get_visible_rect().size.x / 2.0

	if event.pressed:
		if event.position.x < screen_half and _joystick_touch_index == -1:
			# Left side — joystick
			_joystick_touch_index = event.index
			_joystick_center = event.position
			_joystick_active = true
			DebugLog.log("TouchControls", "joystick started at %s" % event.position)
		elif event.position.x >= screen_half and _camera_touch_index == -1:
			# Right side — camera
			_camera_touch_index = event.index
			_camera_last_pos = event.position
	else:
		if event.index == _joystick_touch_index:
			_joystick_touch_index = -1
			_joystick_active = false
			_joystick_vector = Vector2.ZERO
			_update_joystick_visual(Vector2.ZERO)
		elif event.index == _camera_touch_index:
			_camera_touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joystick_touch_index:
		var offset: Vector2 = event.position - _joystick_center
		var max_dist: float = 80.0
		if offset.length() > max_dist:
			offset = offset.normalized() * max_dist
		_joystick_vector = offset / max_dist
		if _joystick_vector.length() < joystick_deadzone:
			_joystick_vector = Vector2.ZERO
		_update_joystick_visual(offset)

	elif event.index == _camera_touch_index:
		var delta: Vector2 = event.position - _camera_last_pos
		_camera_last_pos = event.position
		# Simulate mouse motion for camera look
		var mouse_event := InputEventMouseMotion.new()
		mouse_event.relative = delta * camera_sensitivity * 100.0
		Input.parse_input_event(mouse_event)

func _process(_delta: float) -> void:
	if not _is_mobile:
		return
	# Map joystick vector to movement input actions
	_simulate_input("forward", -_joystick_vector.y > joystick_deadzone)
	_simulate_input("back", _joystick_vector.y > joystick_deadzone)
	_simulate_input("left", -_joystick_vector.x > joystick_deadzone)
	_simulate_input("right", _joystick_vector.x > joystick_deadzone)

func _simulate_input(action: String, active: bool) -> void:
	if active and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not active and Input.is_action_pressed(action):
		Input.action_release(action)

func _update_joystick_visual(offset: Vector2) -> void:
	if _joystick_knob:
		_joystick_knob.position = offset

func _on_jump_pressed() -> void:
	Input.action_press("jump")
	# Release after a short delay
	get_tree().create_timer(0.1).timeout.connect(func() -> void: Input.action_release("jump"))
	DebugLog.log("TouchControls", "jump button pressed")

func _on_interact_pressed() -> void:
	Input.action_press("interact")
	get_tree().create_timer(0.1).timeout.connect(func() -> void: Input.action_release("interact"))
	DebugLog.log("TouchControls", "interact button pressed")

func _on_menu_pressed() -> void:
	Input.action_press("menu")
	get_tree().create_timer(0.1).timeout.connect(func() -> void: Input.action_release("menu"))
	DebugLog.log("TouchControls", "menu button pressed")
