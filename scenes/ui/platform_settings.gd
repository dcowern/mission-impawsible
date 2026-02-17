extends Node
## Platform-specific settings. Applies mobile optimizations automatically.

func _ready() -> void:
	if OS.has_feature("mobile"):
		_apply_mobile_settings()
	else:
		_apply_desktop_settings()

func _apply_mobile_settings() -> void:
	DebugLog.log("Platform", "mobile detected — applying performance settings")

	# Disable MSAA on mobile
	var rid: RID = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_msaa_3d(rid, RenderingServer.VIEWPORT_MSAA_DISABLED)

	# Reduce shadow quality
	RenderingServer.directional_shadow_atlas_set_size(1024, true)

	# Use mobile renderer settings
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	get_viewport().scaling_3d_scale = 0.75

	DebugLog.log("Platform", "mobile: MSAA off, shadows 1024, FSR2 0.75x")

func _apply_desktop_settings() -> void:
	DebugLog.log("Platform", "desktop detected — full quality settings")
