extends SceneTree
## Terrain heightmap PNG generator — creates a 4096×4096 heightmap image.
## The image is then imported by Terrain3D when the scene is loaded in-editor.
##
## Usage: godot --headless -s res://tools/generate_terrain.gd
##
## Biome layout (16km × 16km world):
##   North (-Z): Alpine Peaks (1200-2000m)
##   Center: Central Plains (50-200m)
##   South (+Z): Coast trending to sea level
##   West (-X): Forest, River Valley
##   East (+X): Savanna/Scrub

const IMG_SIZE := 4096        # pixels (maps to 16384m world → 4m per pixel)
const WORLD_SIZE := 16384.0   # meters
const PIXELS_PER_METER: float = IMG_SIZE / WORLD_SIZE  # 0.25

# Elevation constants (meters)
const PLAINS_BASE := 80.0
const PLAINS_VARIATION := 40.0
const ALPINE_MIN := 800.0
const ALPINE_MAX := 2000.0
const FOOTHILLS_BASE := 400.0
const FOREST_BASE := 150.0

var _noise_base: FastNoiseLite
var _noise_detail: FastNoiseLite
var _noise_micro: FastNoiseLite

func _init() -> void:
	print("[DEBUG] TerrainGenerator: generating %dx%d heightmap..." % [IMG_SIZE, IMG_SIZE])
	_setup_noise()

	var img := Image.create(IMG_SIZE, IMG_SIZE, false, Image.FORMAT_RF)
	var min_h := 99999.0
	var max_h := -99999.0

	for py in range(IMG_SIZE):
		for px in range(IMG_SIZE):
			# Map pixel to world coordinates: center of image = world origin
			var world_x: float = (float(px) / IMG_SIZE - 0.5) * WORLD_SIZE
			var world_z: float = (float(py) / IMG_SIZE - 0.5) * WORLD_SIZE

			var h := _compute_height(world_x, world_z)
			img.set_pixel(px, py, Color(h, 0, 0, 1))
			min_h = minf(min_h, h)
			max_h = maxf(max_h, h)

		if py % 512 == 0:
			print("[DEBUG] TerrainGenerator: row %d/%d (%.0f%%)" % [py, IMG_SIZE, 100.0 * py / IMG_SIZE])

	print("[DEBUG] TerrainGenerator: heightmap complete — min=%.1fm max=%.1fm" % [min_h, max_h])

	# Save as EXR (32-bit float) for Terrain3D import
	var path := "res://terrain/heightmap.exr"
	var err := img.save_exr(path, true)  # grayscale=true for single-channel
	if err == OK:
		print("[DEBUG] TerrainGenerator: saved heightmap to %s" % path)
	else:
		print("[DEBUG][ERROR] TerrainGenerator: failed to save heightmap: %s" % error_string(err))

	quit()

func _setup_noise() -> void:
	_noise_base = FastNoiseLite.new()
	_noise_base.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_base.seed = 42
	_noise_base.frequency = 0.0003  # large-scale features

	_noise_detail = FastNoiseLite.new()
	_noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_detail.seed = 137
	_noise_detail.frequency = 0.002  # medium detail

	_noise_micro = FastNoiseLite.new()
	_noise_micro.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_micro.seed = 256
	_noise_micro.frequency = 0.01   # micro detail

func _compute_height(world_x: float, world_z: float) -> float:
	var half := WORLD_SIZE / 2.0
	# Normalize to [-1, 1]
	var nx: float = world_x / half  # -1=west, +1=east
	var nz: float = world_z / half  # -1=north, +1=south

	# Noise layers
	var base_h: float = _noise_base.get_noise_2d(world_x, world_z) * 500.0
	var detail_h: float = _noise_detail.get_noise_2d(world_x, world_z) * 50.0
	var micro_h: float = _noise_micro.get_noise_2d(world_x, world_z) * 5.0
	var raw_noise: float = base_h + detail_h + micro_h

	var height: float = 0.0

	# --- Latitude bands (north to south) ---
	if nz < -0.5:
		# Alpine Peaks (north)
		var t: float = remap(nz, -1.0, -0.5, 1.0, 0.0)
		var alpine_h: float = ALPINE_MIN + abs(raw_noise) / 500.0 * (ALPINE_MAX - ALPINE_MIN)
		height = lerpf(FOOTHILLS_BASE + raw_noise * 0.5, alpine_h, t)
	elif nz < -0.2:
		# Foothills
		var t: float = remap(nz, -0.5, -0.2, 1.0, 0.0)
		height = lerpf(PLAINS_BASE + raw_noise * 0.3, FOOTHILLS_BASE + raw_noise * 0.5, t)
	elif nz < 0.2:
		# Central Plains — gentle rolling terrain
		height = PLAINS_BASE + detail_h * (PLAINS_VARIATION / 50.0) + micro_h
	elif nz < 0.5:
		# Transition to coast
		var t: float = remap(nz, 0.2, 0.5, 0.0, 1.0)
		var plains_h: float = PLAINS_BASE + detail_h * (PLAINS_VARIATION / 50.0)
		var low_h: float = 20.0 + detail_h * 0.3
		height = lerpf(plains_h, low_h, t)
	else:
		# Coast
		var t: float = remap(nz, 0.5, 1.0, 0.0, 1.0)
		var low_h: float = 20.0 + detail_h * 0.3
		height = lerpf(low_h, micro_h * 0.4, t)

	# --- Longitude modifiers ---
	# West forest: slightly elevated
	if nx < -0.3:
		var west_t: float = remap(nx, -1.0, -0.3, 1.0, 0.0)
		height += west_t * 50.0

	# River valley carve (southwest)
	if nx < -0.1 and nx > -0.5 and nz > 0.0 and nz < 0.8:
		var river_center_x: float = -0.3
		var river_dist: float = abs(nx - river_center_x)
		var river_width: float = 0.05  # normalized width
		if river_dist < river_width:
			var carve_t: float = 1.0 - (river_dist / river_width)
			height -= carve_t * carve_t * 20.0

	# East savanna: slightly lower, flatter
	if nx > 0.3:
		var east_t: float = remap(nx, 0.3, 1.0, 0.0, 1.0)
		height = lerpf(height, height * 0.7, east_t * 0.3)

	return maxf(height, -2.0)
