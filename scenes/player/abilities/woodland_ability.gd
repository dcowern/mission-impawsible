class_name WoodlandAbility
extends AbilityBase
## Grows vine platforms on surfaces. Higher levels → longer/sturdier vines.

const VINE_RANGE: float = 15.0
const BASE_VINE_LENGTH: float = 3.0
const BASE_VINE_DURATION: float = 15.0

func _init() -> void:
	discipline = "woodland"
	cooldown = 4.0

func _execute(camera: Camera3D) -> void:
	var vine_length: float = BASE_VINE_LENGTH + (_level - 1) * 1.0
	var vine_duration: float = BASE_VINE_DURATION + (_level - 1) * 5.0
	DebugLog.log("Ability:woodland", "casting: vine_length=%.1f duration=%.1fs" % [vine_length, vine_duration])

	# Raycast to find surface
	var space := camera.get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_basis.z) * VINE_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var result: Dictionary = space.intersect_ray(query)

	if result.is_empty():
		DebugLog.log("Ability:woodland", "no surface hit — vine fizzled")
		_spawn_fizzle_particles(from + (-camera.global_basis.z) * 2.0)
		return

	var hit_pos: Vector3 = result["position"]
	var hit_normal: Vector3 = result["normal"]
	DebugLog.log("Ability:woodland", "surface hit at %s normal=%s" % [hit_pos, hit_normal])
	_spawn_vine_platform(hit_pos, hit_normal, vine_length, vine_duration)

func _spawn_vine_platform(pos: Vector3, normal: Vector3, length: float, duration: float) -> void:
	DebugLog.log("Ability:woodland", "growing vine platform at %s" % pos)

	var vine := StaticBody3D.new()
	vine.name = "VinePlatform"

	# Box-shaped platform
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, 0.15, 1.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	vine.add_child(col)

	# Visual — green box with bark-like appearance
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, 0.15, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.15)
	mat.roughness = 0.9
	mesh.material = mat
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	vine.add_child(mesh_inst)

	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(vine)
		vine.global_position = pos + normal * 0.1

		# Grow animation — scale from 0 to full
		vine.scale = Vector3(0.01, 0.01, 0.01)
		var tween := tree.create_tween()
		tween.tween_property(vine, "scale", Vector3.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		_spawn_grow_particles(pos)

		# Auto-remove after duration
		var timer := Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.autostart = true
		vine.add_child(timer)
		timer.timeout.connect(func() -> void:
			DebugLog.log("Ability:woodland", "vine platform expired")
			# Shrink before removing
			var shrink := tree.create_tween()
			shrink.tween_property(vine, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
			shrink.tween_callback(vine.queue_free)
		)

func _spawn_grow_particles(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.6
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.05
	pmesh.height = 0.1
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 60.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 3.0
	pmat.gravity = Vector3(0, -2, 0)
	pmat.color = Color(0.2, 0.8, 0.2)
	particles.process_material = pmat

	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(particles)
		particles.global_position = pos
		var cleanup := Timer.new()
		cleanup.wait_time = 1.5
		cleanup.one_shot = true
		cleanup.autostart = true
		particles.add_child(cleanup)
		cleanup.timeout.connect(particles.queue_free)

func _spawn_fizzle_particles(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 8
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.emitting = true
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.03
	pmesh.height = 0.06
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3(0, -1, 0)
	pmat.color = Color(0.3, 0.6, 0.2, 0.5)
	particles.process_material = pmat

	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(particles)
		particles.global_position = pos
		var cleanup := Timer.new()
		cleanup.wait_time = 1.0
		cleanup.one_shot = true
		cleanup.autostart = true
		particles.add_child(cleanup)
		cleanup.timeout.connect(particles.queue_free)
