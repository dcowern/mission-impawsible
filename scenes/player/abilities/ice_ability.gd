class_name IceAbility
extends AbilityBase
## Freezes target or creates ice patch on ground.
## Higher levels → longer freeze duration, larger ice patch area.

const FREEZE_RANGE: float = 20.0
const BASE_FREEZE_DURATION: float = 3.0
const BASE_PATCH_RADIUS: float = 2.0

func _init() -> void:
	discipline = "ice"
	cooldown = 3.0

func _execute(camera: Camera3D) -> void:
	var freeze_duration: float = BASE_FREEZE_DURATION + (_level - 1) * 1.5
	var patch_radius: float = BASE_PATCH_RADIUS + (_level - 1) * 0.5
	DebugLog.log("Ability:ice", "casting: freeze_duration=%.1fs patch_radius=%.1f" % [freeze_duration, patch_radius])

	# Raycast to find target
	var space := camera.get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_basis.z) * FREEZE_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var result: Dictionary = space.intersect_ray(query)

	if result.is_empty():
		DebugLog.log("Ability:ice", "no target hit — casting ice particles into air")
		_spawn_ice_particles(from + (-camera.global_basis.z) * 3.0)
		return

	var hit_pos: Vector3 = result["position"]
	var hit_body: Object = result["collider"]
	DebugLog.log("Ability:ice", "hit %s at %s" % [hit_body, hit_pos])

	# If we hit the ground (static body), create ice patch
	if hit_body is StaticBody3D:
		_create_ice_patch(hit_pos, patch_radius, freeze_duration)
	else:
		# Try to freeze the target
		_apply_freeze(hit_body, freeze_duration)
		_spawn_ice_particles(hit_pos)

func _create_ice_patch(pos: Vector3, radius: float, duration: float) -> void:
	DebugLog.log("Ability:ice", "creating ice patch at %s radius=%.1f duration=%.1fs" % [pos, radius, duration])

	var patch := StaticBody3D.new()
	patch.name = "IcePatch"

	# Flat cylinder collision
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.05
	var col := CollisionShape3D.new()
	col.shape = shape
	patch.add_child(col)

	# Visual — translucent blue disc
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.8, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	patch.add_child(mesh_inst)

	_spawn_ice_particles(pos)

	var tree := camera_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(patch)
		patch.global_position = pos + Vector3(0, 0.025, 0)

		# Auto-remove after duration
		var timer := Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.autostart = true
		patch.add_child(timer)
		timer.timeout.connect(func() -> void:
			DebugLog.log("Ability:ice", "ice patch expired")
			patch.queue_free()
		)

func _apply_freeze(target: Object, duration: float) -> void:
	DebugLog.log("Ability:ice", "freezing target %s for %.1fs" % [target, duration])
	# Phase 5 NPCs will check for frozen status — for now, log the action

func _spawn_ice_particles(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 25
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.8
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.04
	pmesh.height = 0.08
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 120.0
	pmat.initial_velocity_min = 2.0
	pmat.initial_velocity_max = 4.0
	pmat.gravity = Vector3(0, -3, 0)
	pmat.color = Color(0.5, 0.8, 1.0)
	particles.process_material = pmat

	var tree := camera_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(particles)
		particles.global_position = pos
		var cleanup := Timer.new()
		cleanup.wait_time = 1.0
		cleanup.one_shot = true
		cleanup.autostart = true
		particles.add_child(cleanup)
		cleanup.timeout.connect(particles.queue_free)

func camera_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree
