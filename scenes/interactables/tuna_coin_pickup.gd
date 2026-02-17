extends Area3D
## Tuna Coin pickup — bobbing gold cylinder that awards 1 tuna coin on collection.
## Place in the world; the player walks into it to collect.

class_name TunaCoinPickup

@export var coin_value: int = 1
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.15
@export var spin_speed: float = 2.0
@export var pickup_sound: AudioStream

var _base_y: float = 0.0
var _collected: bool = false

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	if not pickup_sound:
		pickup_sound = _generate_beep_sound()
	DebugLog.log("TunaCoin", "spawned at %s" % global_position)

func _process(delta: float) -> void:
	if _collected:
		return
	# Bob up and down
	position.y = _base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height
	# Spin
	rotation.y += spin_speed * delta

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	# Only collect on player contact
	if body.is_in_group("Player") or body.name == "CatPlayer":
		_collected = true
		DebugLog.log("TunaCoin", "collected by %s at %s (value=%d)" % [body.name, global_position, coin_value])
		GameState.add_tuna_coins(coin_value)
		# Play pickup sound then remove
		if pickup_sound:
			Audio.play_sound_3d(pickup_sound).global_position = global_position
		queue_free()

static func _generate_beep_sound() -> AudioStream:
	# Generate a short ascending beep as placeholder pickup sound
	var sample_rate := 22050
	var duration := 0.15
	var sample_count := int(sample_rate * duration)
	var data := PackedVector2Array()
	data.resize(sample_count)
	for i in sample_count:
		var t: float = float(i) / sample_rate
		var freq: float = 880.0 + t * 2000.0  # ascending chirp
		var envelope: float = 1.0 - (t / duration)  # fade out
		var sample: float = sin(t * freq * TAU) * envelope * 0.3
		data[i] = Vector2(sample, sample)
	var stream := AudioStreamWAV.new()
	# Pack to 16-bit PCM
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 4)  # 2 bytes * 2 channels
	for i in sample_count:
		var val_l := int(clampf(data[i].x, -1.0, 1.0) * 32767)
		var val_r := int(clampf(data[i].y, -1.0, 1.0) * 32767)
		bytes.encode_s16(i * 4, val_l)
		bytes.encode_s16(i * 4 + 2, val_r)
	stream.data = bytes
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	return stream
