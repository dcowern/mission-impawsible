extends Node3D
## Ability Shrine — ancient stone structure where tuna coins are spent to unlock abilities.
## Player enters the trigger area, presses interact to open the unlock UI.

@onready var _interact_area: Area3D = $InteractArea
@onready var _unlock_ui: CanvasLayer = $AbilityUnlockUI

var _player_in_range: bool = false

func _ready() -> void:
	DebugLog.log("AbilityShrine", "loaded at %s" % global_position)
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)
	_unlock_ui.ui_closed.connect(_on_ui_closed)

func _input(event: InputEvent) -> void:
	if _player_in_range and not _unlock_ui.visible:
		if event.is_action_pressed("interact"):
			_unlock_ui.open()
			get_viewport().set_input_as_handled()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "CatPlayer":
		_player_in_range = true
		DebugLog.log("AbilityShrine", "player entered shrine area")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "CatPlayer":
		_player_in_range = false
		DebugLog.log("AbilityShrine", "player left shrine area")

func _on_ui_closed() -> void:
	_player_in_range = false  # Reset to prevent immediate re-open
