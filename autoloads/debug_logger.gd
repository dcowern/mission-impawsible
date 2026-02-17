# autoloads/debug_logger.gd
extends Node

var enabled: bool = true
var log_to_file: bool = false
var _log_file: FileAccess = null

func _ready():
	if log_to_file:
		_log_file = FileAccess.open("user://debug_log.txt", FileAccess.WRITE)
		print("[DEBUG] DebugLogger: file logging enabled to user://debug_log.txt")

func log(context: String, message: String) -> void:
	if not enabled:
		return
	var line := "[DEBUG] %s: %s" % [context, message]
	print(line)
	if _log_file:
		_log_file.store_line(line)

func log_state_change(context: String, var_name: String, old_val, new_val) -> void:
	if not enabled:
		return
	if old_val != new_val:
		self.log(context, "%s changed: %s -> %s" % [var_name, old_val, new_val])

func log_error(context: String, message: String) -> void:
	var line := "[DEBUG][ERROR] %s: %s" % [context, message]
	push_error(line)
	print(line)
	if _log_file:
		_log_file.store_line(line)
