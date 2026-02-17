extends CanvasLayer
## Ability Unlock UI — shown when interacting with the Ability Shrine.
## Displays 5 magic disciplines, current levels, and unlock buttons.

signal ui_closed

@onready var _panel: PanelContainer = $CenterContainer/Panel
@onready var _grid: GridContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/AbilityGrid
@onready var _coin_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Header/CoinLabel
@onready var _close_btn: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton

var _ability_rows: Dictionary = {}  # discipline_name -> {label, level_label, button}
var _is_open: bool = false

const DISCIPLINE_DISPLAY := {
	"fire": {"name": "Fire", "color": Color(1.0, 0.3, 0.1)},
	"ice": {"name": "Ice", "color": Color(0.3, 0.7, 1.0)},
	"woodland": {"name": "Woodland", "color": Color(0.2, 0.8, 0.2)},
	"dragon_taming": {"name": "Dragon Taming", "color": Color(0.8, 0.2, 0.8)},
	"creature_speak": {"name": "Creature Speak", "color": Color(1.0, 0.8, 0.2)},
}

func _ready() -> void:
	visible = false
	_close_btn.pressed.connect(_close)
	_build_ability_rows()
	SignalBus.tuna_coins_changed.connect(_on_coins_changed)

func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func open() -> void:
	DebugLog.log("AbilityUnlockUI", "opened, coins=%d" % GameState.tuna_coins)
	_is_open = true
	visible = true
	_refresh_all()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close() -> void:
	DebugLog.log("AbilityUnlockUI", "closed")
	_is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui_closed.emit()

func _build_ability_rows() -> void:
	for discipline in GameState.MAGIC_DISCIPLINES:
		var display: Dictionary = DISCIPLINE_DISPLAY[discipline]

		var name_label := Label.new()
		name_label.text = display["name"]
		name_label.add_theme_color_override("font_color", display["color"])
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_grid.add_child(name_label)

		var level_label := Label.new()
		level_label.text = "Lv. 0"
		level_label.add_theme_font_size_override("font_size", 20)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.custom_minimum_size.x = 80
		_grid.add_child(level_label)

		var unlock_btn := Button.new()
		unlock_btn.text = "Unlock (1 coin)"
		unlock_btn.custom_minimum_size = Vector2(160, 36)
		unlock_btn.pressed.connect(_on_unlock_pressed.bind(discipline))
		_grid.add_child(unlock_btn)

		_ability_rows[discipline] = {
			"name_label": name_label,
			"level_label": level_label,
			"button": unlock_btn,
		}

func _refresh_all() -> void:
	_coin_label.text = "Tuna Coins: %d" % GameState.tuna_coins
	for discipline in GameState.MAGIC_DISCIPLINES:
		var level: int = GameState.get_ability_level(discipline)
		var row: Dictionary = _ability_rows[discipline]
		row["level_label"].text = "Lv. %d" % level
		if GameState.tuna_coins <= 0:
			row["button"].disabled = true
			row["button"].text = "No Coins"
		else:
			row["button"].disabled = false
			row["button"].text = "Upgrade (1 coin)" if level > 0 else "Unlock (1 coin)"

func _on_unlock_pressed(discipline: String) -> void:
	DebugLog.log("AbilityUnlockUI", "unlock attempt: %s, coins=%d" % [discipline, GameState.tuna_coins])
	var success := GameState.unlock_ability(discipline)
	if success:
		DebugLog.log("AbilityUnlockUI", "unlocked %s successfully" % discipline)
	else:
		DebugLog.log("AbilityUnlockUI", "unlock %s FAILED" % discipline)
	_refresh_all()

func _on_coins_changed(_old: int, _new: int) -> void:
	if _is_open:
		_refresh_all()
