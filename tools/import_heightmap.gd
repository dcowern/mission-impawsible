extends SceneTree
## Imports the generated heightmap.exr into Terrain3D region data.
## Usage: godot --headless -s res://tools/import_heightmap.gd
##
## With region_size=256 and vertex_spacing=4.0:
##   Each region = 256 * 4 = 1024m
##   32 regions per axis = 32768m (plenty for 16km)
##   Position range = ±16384

const HEIGHTMAP_PATH := "res://terrain/heightmap.exr"
const DATA_DIR := "res://terrain/data"
const VERTEX_SPACING := 4.0

var _terrain: Terrain3D
var _frame_count := 0

func _init() -> void:
	print("[DEBUG] HeightmapImporter: initializing...")
	_terrain = Terrain3D.new()
	_terrain.vertex_spacing = VERTEX_SPACING
	_terrain.data_directory = DATA_DIR
	root.add_child(_terrain)

func _process(_delta: float) -> bool:
	_frame_count += 1
	if _frame_count == 3:
		_do_import()
		return true
	return false

func _do_import() -> void:
	print("[DEBUG] HeightmapImporter: terrain.data = %s" % _terrain.data)
	print("[DEBUG] HeightmapImporter: region_size=%d vertex_spacing=%.1f" % [
		_terrain.region_size, _terrain.vertex_spacing])

	if not _terrain.data:
		print("[DEBUG][ERROR] HeightmapImporter: terrain.data is null")
		_cleanup_and_quit()
		return

	# Load heightmap EXR
	var img: Image = Terrain3DUtil.load_image(HEIGHTMAP_PATH, ResourceLoader.CACHE_MODE_IGNORE)
	if not img:
		print("[DEBUG][ERROR] HeightmapImporter: failed to load %s" % HEIGHTMAP_PATH)
		_cleanup_and_quit()
		return

	print("[DEBUG] HeightmapImporter: loaded heightmap %dx%d" % [img.get_width(), img.get_height()])
	var min_max: Vector2 = Terrain3DUtil.get_min_max(img)
	print("[DEBUG] HeightmapImporter: height range: min=%.1f max=%.1f" % [min_max.x, min_max.y])

	var imported_images: Array[Image]
	imported_images.resize(Terrain3DRegion.TYPE_MAX)
	imported_images[Terrain3DRegion.TYPE_HEIGHT] = img

	# Image is 4096px, vertex_spacing=4.0
	# At import_scale=1.0, each pixel = 1 vertex * 4m = 4m → 4096 * 4 = 16384m ✓
	# Origin at (0,0,0) centers the import
	print("[DEBUG] HeightmapImporter: importing at origin=(0,0,0) scale=1.0")
	_terrain.data.import_images(imported_images, Vector3.ZERO, 0.0, 1.0)

	var region_count: int = _terrain.data.get_region_count()
	print("[DEBUG] HeightmapImporter: %d regions created" % region_count)

	if region_count > 0:
		_terrain.data.save_directory(DATA_DIR)
		var hr: Vector2 = _terrain.data.get_height_range()
		print("[DEBUG] HeightmapImporter: saved. Height range: min=%.1f max=%.1f" % [hr.x, hr.y])
	else:
		print("[DEBUG][ERROR] HeightmapImporter: no regions created — check import params")

	_cleanup_and_quit()

func _cleanup_and_quit() -> void:
	if _terrain:
		_terrain.queue_free()
	quit()
