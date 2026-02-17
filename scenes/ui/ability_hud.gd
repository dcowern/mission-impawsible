extends CanvasLayer
## Ability HUD — 5 slots at bottom center showing ability state.
## 1-5 keys to select, LMB/RT to activate.

const DISCIPLINE_INFO := {
	"fire": {"name": "Fire", "color": Color(1.0, 0.4, 0.05), "key": "1"},
	"ice": {"name": "Ice", "color": Color(0.3, 0.7, 1.0), "key": "2"},
	"woodland": {"name": "Woodland", "color": Color(0.2, 0.8, 0.2), "key": "3"},
	"dragon_taming": {"name": "Dragon", "color": Color(0.8, 0.5, 1.0), "key": "4"},
	"creature_speak": {"name": "Speak", "color": Color(1.0, 0.85, 0.3), "key": "5"},
}

var _selected_index: int = -1
var _slots: Array[Control] = []
var _cooldown_bars: Array[ProgressBar] = []
var _lock_icons: Array[Label] = []
var _key_labels: Array[Label] = []
var _abilities: Array[AbilityBase] = []

@onready var _container: HBoxContainer = $MarginContainer/HBoxContainer

func _ready() -> void:
	_build_slots()
	SignalBus.ability_unlocked.connect(_on_ability_unlocked)
	DebugLog.log("AbilityHUD", "initialized with %d slots" % _slots.size())

func set_abilities(ability_list: Array[AbilityBase]) -> void:
	_abilities = ability_list
	DebugLog.log("AbilityHUD", "abilities registered: %d" % _abilities.size())

func _build_slots() -> void:
	var disciplines: Array = GameState.MAGIC_DISCIPLINES
	for i in range(disciplines.size()):
		var discipline: String = disciplines[i]
		var info: Dictionary = DISCIPLINE_INFO[discipline]

		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(60, 70)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
		style.border_color = info["color"]
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)

		# Key label
		var key_label := Label.new()
		key_label.text = info["key"]
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 10)
		key_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(key_label)
		_key_labels.append(key_label)

		# Ability name
		var name_label := Label.new()
		name_label.text = info["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", info["color"])
		vbox.add_child(name_label)

		# Lock icon (shown when locked)
		var lock_label := Label.new()
		lock_label.text = "LOCKED"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 8)
		lock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		lock_label.visible = GameState.get_ability_level(discipline) <= 0
		vbox.add_child(lock_label)
		_lock_icons.append(lock_label)

		# Cooldown bar
		var cd_bar := ProgressBar.new()
		cd_bar.custom_minimum_size = Vector2(50, 6)
		cd_bar.max_value = 1.0
		cd_bar.value = 0.0
		cd_bar.show_percentage = false
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = info["color"].darkened(0.5)
		cd_bar.add_theme_stylebox_override("fill", bar_style)
		var bar_bg := StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.15, 0.15, 0.15)
		cd_bar.add_theme_stylebox_override("background", bar_bg)
		vbox.add_child(cd_bar)
		_cooldown_bars.append(cd_bar)

		_container.add_child(slot)
		_slots.append(slot)

	_refresh_all()

func _process(_delta: float) -> void:
	# Update cooldown bars from ability nodes
	for i in range(_abilities.size()):
		if i < _cooldown_bars.size():
			_cooldown_bars[i].value = _abilities[i].get_cooldown_percent()

func _input(event: InputEvent) -> void:
	# Number keys 1-5 to select
	for i in range(5):
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1 + i:
				_select_ability(i)
				return

	# LMB or action_primary to activate
	if event.is_action_pressed("action_primary"):
		_activate_selected()

func _select_ability(index: int) -> void:
	if index < 0 or index >= GameState.MAGIC_DISCIPLINES.size():
		return
	var discipline: String = GameState.MAGIC_DISCIPLINES[index]
	if GameState.get_ability_level(discipline) <= 0:
		DebugLog.log("AbilityHUD", "cannot select %s — locked" % discipline)
		return
	_selected_index = index
	_refresh_selection()
	DebugLog.log("AbilityHUD", "selected ability: %s (slot %d)" % [discipline, index + 1])

func _activate_selected() -> void:
	if _selected_index < 0 or _selected_index >= _abilities.size():
		return
	var ability: AbilityBase = _abilities[_selected_index]
	# Get camera from player
	var camera := get_viewport().get_camera_3d()
	if camera:
		ability.use(camera)

func _refresh_selection() -> void:
	for i in range(_slots.size()):
		var style: StyleBoxFlat = _slots[i].get_theme_stylebox("panel") as StyleBoxFlat
		if i == _selected_index:
			style.border_color = Color.WHITE
			style.set_border_width_all(3)
		else:
			var discipline: String = GameState.MAGIC_DISCIPLINES[i]
			style.border_color = DISCIPLINE_INFO[discipline]["color"]
			style.set_border_width_all(2)

func _refresh_all() -> void:
	for i in range(GameState.MAGIC_DISCIPLINES.size()):
		if i < _lock_icons.size():
			var discipline: String = GameState.MAGIC_DISCIPLINES[i]
			_lock_icons[i].visible = GameState.get_ability_level(discipline) <= 0

func _on_ability_unlocked(ability_name: String, _level: int) -> void:
	_refresh_all()
	DebugLog.log("AbilityHUD", "refreshed after %s unlocked" % ability_name)
