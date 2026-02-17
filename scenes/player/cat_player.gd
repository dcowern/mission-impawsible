class_name CatPlayer
extends CogitoPlayer

## Cat-proportioned player controller extending COGITO's CogitoPlayer.
## Adds debug logging for movement states, jumps, landings, and fall damage.

const FALL_DAMAGE_MULTIPLIER: float = 0.3

var _prev_on_floor: bool = true
var _prev_movement_state: String = "idle"

func _ready() -> void:
	super._ready()
	DebugLog.log("CatPlayer", "initialized: walk=%.1f sprint=%.1f jump_vel=%.1f fall_dmg=%d" % [
		WALKING_SPEED, SPRINTING_SPEED, JUMP_VELOCITY, fall_damage])

func _physics_process(delta: float) -> void:
	var pre_floor := is_on_floor()
	var pre_vel := velocity

	super._physics_process(delta)

	_log_floor_transitions(pre_floor)
	_log_movement_state()

func _log_floor_transitions(was_on_floor_before: bool) -> void:
	var on_floor_now := is_on_floor()
	if was_on_floor_before and not on_floor_now:
		DebugLog.log("CatPlayer", "left ground, vel.y=%.2f" % velocity.y)
	elif not was_on_floor_before and on_floor_now:
		DebugLog.log("CatPlayer", "landed, vel.y=%.2f last_vel.y=%.2f" % [velocity.y, last_velocity.y])
		if fall_damage > 0 and last_velocity.y <= fall_damage_threshold:
			DebugLog.log("CatPlayer", "fall damage triggered: %d HP (threshold=%.1f, vel=%.2f)" % [
				fall_damage, fall_damage_threshold, last_velocity.y])

func _log_movement_state() -> void:
	var state: String = "idle"
	if not is_on_floor():
		state = "airborne"
	elif is_crouching:
		state = "crouching"
	elif is_sprinting:
		state = "sprinting"
	elif velocity.length() > 0.1:
		state = "walking"

	if state != _prev_movement_state:
		DebugLog.log_state_change("CatPlayer", "movement_state", _prev_movement_state, state)
		_prev_movement_state = state
