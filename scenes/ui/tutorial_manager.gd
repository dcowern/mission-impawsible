extends CanvasLayer
## Contextual tutorial prompts for the first 5 minutes.
## Non-intrusive: shows tips based on what the player hasn't done yet.

const TUTORIALS := {
	"movement": {
		"text": "Use WASD to move around.",
		"condition": "has_moved",
	},
	"look": {
		"text": "Move the mouse to look around.",
		"condition": "has_looked",
	},
	"interact": {
		"text": "Press F to interact with objects.",
		"condition": "has_interacted",
	},
	"talk": {
		"text": "Talk to the Elder Cat to learn about your quest.",
		"condition": "has_talked",
	},
	"coin": {
		"text": "Pick up Tuna Coins to power up your abilities.",
		"condition": "has_collected_coin",
	},
	"shrine": {
		"text": "Visit the Ability Shrine to unlock magic powers.",
		"condition": "has_visited_shrine",
	},
	"ability": {
		"text": "Press 1-5 to select abilities, LMB to use them.",
		"condition": "has_used_ability",
	},
}

var _completed: Dictionary = {}
var _current_tutorial: String = ""
var _show_timer: float = 0.0
var _display_duration: float = 5.0
var _tutorial_order: Array = ["movement", "look", "interact", "talk", "coin", "shrine", "ability"]
var _current_index: int = 0

@onready var _label: Label = $TutorialLabel

func _ready() -> void:
	_label.visible = false
	for key in TUTORIALS:
		_completed[key] = false

	# Connect signals to track progress
	SignalBus.tuna_coins_changed.connect(_on_coins_changed)
	SignalBus.ability_used.connect(_on_ability_used)

	DebugLog.log("Tutorial", "initialized with %d steps" % TUTORIALS.size())

	# Show first tutorial after a short delay
	get_tree().create_timer(2.0).timeout.connect(_show_next_tutorial)

func _process(delta: float) -> void:
	if _show_timer > 0:
		_show_timer -= delta
		if _show_timer <= 0:
			_label.visible = false
			# Show next tutorial after a pause
			get_tree().create_timer(3.0).timeout.connect(_show_next_tutorial)

	# Track movement
	if not _completed["movement"] and Input.is_action_pressed("forward"):
		_complete_tutorial("movement")
	if not _completed["look"]:
		# Track any camera movement (hard to detect in headless, mark after movement)
		if _completed["movement"]:
			_complete_tutorial("look")

func _show_next_tutorial() -> void:
	while _current_index < _tutorial_order.size():
		var key: String = _tutorial_order[_current_index]
		if not _completed[key]:
			_show_tutorial(key)
			return
		_current_index += 1
	DebugLog.log("Tutorial", "all tutorials completed!")

func _show_tutorial(key: String) -> void:
	_current_tutorial = key
	_label.text = TUTORIALS[key]["text"]
	_label.visible = true
	_show_timer = _display_duration
	DebugLog.log("Tutorial", "showing: %s — %s" % [key, TUTORIALS[key]["text"]])

func _complete_tutorial(key: String) -> void:
	if _completed[key]:
		return
	_completed[key] = true
	DebugLog.log("Tutorial", "completed: %s" % key)
	if key == _current_tutorial:
		_label.visible = false
		_show_timer = 0.0
		_current_index += 1
		get_tree().create_timer(1.0).timeout.connect(_show_next_tutorial)

func _on_coins_changed(_old: int, _new: int) -> void:
	_complete_tutorial("coin")

func _on_ability_used(_discipline: String, _target: Node) -> void:
	_complete_tutorial("ability")
