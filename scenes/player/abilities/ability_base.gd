class_name AbilityBase
extends Node

@export var discipline: String = ""
@export var cooldown: float = 2.0
@export var stamina_cost: float = 10.0

var _cooldown_timer: float = 0.0
var _level: int = 0

func _ready() -> void:
	_level = GameState.get_ability_level(discipline)
	SignalBus.ability_unlocked.connect(_on_ability_unlocked)
	DebugLog.log("Ability:%s" % discipline, "initialized at level %d" % _level)

func _process(delta: float) -> void:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

func can_use() -> bool:
	if _level <= 0:
		DebugLog.log("Ability:%s" % discipline, "cannot use — not unlocked")
		return false
	if _cooldown_timer > 0:
		DebugLog.log("Ability:%s" % discipline, "cannot use — on cooldown (%.1fs remaining)" % _cooldown_timer)
		return false
	return true

func use(camera: Camera3D) -> void:
	if not can_use():
		return
	_cooldown_timer = cooldown
	DebugLog.log("Ability:%s" % discipline, "USED at level %d" % _level)
	SignalBus.ability_used.emit(discipline, null)
	_execute(camera)

# Override in subclasses
func _execute(_camera: Camera3D) -> void:
	pass

func _on_ability_unlocked(ability_name: String, level: int) -> void:
	if ability_name == discipline:
		_level = level
		DebugLog.log("Ability:%s" % discipline, "level updated to %d" % _level)

func get_cooldown_percent() -> float:
	if cooldown <= 0:
		return 0.0
	return clampf(_cooldown_timer / cooldown, 0.0, 1.0)
