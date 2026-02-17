extends CanvasLayer
## HUD element displaying the player's tuna coin count.
## Updates reactively via SignalBus.tuna_coins_changed.

@onready var _label: Label = $MarginContainer/HBoxContainer/CoinCount
@onready var _icon: TextureRect = $MarginContainer/HBoxContainer/CoinIcon

var _tween: Tween

func _ready() -> void:
	_update_display(GameState.tuna_coins)
	SignalBus.tuna_coins_changed.connect(_on_coins_changed)
	DebugLog.log("TunaCoinDisplay", "HUD initialized, coins=%d" % GameState.tuna_coins)

func _on_coins_changed(old_amount: int, new_amount: int) -> void:
	DebugLog.log("TunaCoinDisplay", "coin display updated: %d → %d" % [old_amount, new_amount])
	_update_display(new_amount)
	_animate_change()

func _update_display(amount: int) -> void:
	_label.text = str(amount)

func _animate_change() -> void:
	# Brief scale-up flash on coin change
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_label.scale = Vector2(1.4, 1.4)
	_tween.tween_property(_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
