extends SceneTree

func _init() -> void:
	print("[DEBUG] Testing Terrain3D instantiation...")
	var terrain := Terrain3D.new()
	print("[DEBUG] Terrain3D created: %s" % terrain)
	terrain.data_directory = "res://terrain/data"
	print("[DEBUG] data_directory set")
	root.add_child(terrain)
	print("[DEBUG] Added to tree")
	print("[DEBUG] data object: %s" % terrain.data)
	print("[DEBUG] region_size: %d" % terrain.region_size)
	terrain.queue_free()
	print("[DEBUG] Terrain3D test passed")
	quit()
