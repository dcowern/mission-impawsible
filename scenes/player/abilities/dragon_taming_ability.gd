class_name DragonTamingAbility
extends AbilityBase
## Golden targeting beam for taming dragons. Full functionality in Phase 5.
## Higher levels → faster taming, more powerful dragons, riding at level 3+.

const TAME_RANGE: float = 25.0
const BASE_TAME_RATE: float = 1.0  # taming progress per second

var _beam: MeshInstance3D = null
var _beam_particles: GPUParticles3D = null
var _is_channeling: bool = false
var _channel_target: Node3D = null

func _init() -> void:
	discipline = "dragon_taming"
	cooldown = 1.0  # Short cooldown — it's a channeled ability

func _execute(camera: Camera3D) -> void:
	var tame_rate: float = BASE_TAME_RATE * _level
	DebugLog.log("Ability:dragon_taming", "activating taming beam: tame_rate=%.1f/s range=%.0fm" % [tame_rate, TAME_RANGE])

	# Raycast to find dragon target
	var space := camera.get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_basis.z) * TAME_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 2  # World + NPCs
	var result: Dictionary = space.intersect_ray(query)

	var beam_end: Vector3
	if result.is_empty():
		beam_end = to
		DebugLog.log("Ability:dragon_taming", "no target — beam into empty space")
	else:
		beam_end = result["position"]
		var hit_body: Object = result["collider"]
		DebugLog.log("Ability:dragon_taming", "beam hit: %s" % hit_body)
		# Phase 5: check if hit_body is a Dragon NPC and apply taming

	_spawn_beam(camera.global_position, beam_end)

func _spawn_beam(from_pos: Vector3, to_pos: Vector3) -> void:
	# Create a golden beam between two points
	var direction: Vector3 = to_pos - from_pos
	var length: float = direction.length()
	var midpoint: Vector3 = from_pos + direction * 0.5

	var beam := MeshInstance3D.new()
	beam.name = "TamingBeam"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.03
	mesh.bottom_radius = 0.03
	mesh.height = length
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	mat.emission_energy_multiplier = 2.0
	mesh.material = mat
	beam.mesh = mesh

	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(beam)
		beam.global_position = midpoint
		# Orient cylinder along the beam direction
		if direction.normalized().abs() != Vector3.UP:
			beam.look_at(to_pos, Vector3.UP)
			beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		else:
			beam.rotation.x = 0

		_spawn_beam_particles(from_pos, to_pos)

		# Auto-remove beam after short display
		var timer := Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = true
		timer.autostart = true
		beam.add_child(timer)
		timer.timeout.connect(func() -> void:
			DebugLog.log("Ability:dragon_taming", "beam faded")
			beam.queue_free()
		)

func _spawn_beam_particles(from_pos: Vector3, to_pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 15
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emitting = true
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.04
	pmesh.height = 0.08
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 30.0
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3.ZERO
	pmat.color = Color(1.0, 0.85, 0.3)
	particles.process_material = pmat

	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(particles)
		particles.global_position = to_pos
		var cleanup := Timer.new()
		cleanup.wait_time = 1.0
		cleanup.one_shot = true
		cleanup.autostart = true
		particles.add_child(cleanup)
		cleanup.timeout.connect(particles.queue_free)
