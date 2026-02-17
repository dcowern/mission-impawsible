class_name CreatureSpeakAbility
extends AbilityBase
## Enables conversation with non-cat creatures. Full dialogue in Phase 6.
## Higher levels → speak with more creature types, get better information.

const SPEAK_RANGE: float = 10.0

func _init() -> void:
	discipline = "creature_speak"
	cooldown = 1.5

func _execute(camera: Camera3D) -> void:
	DebugLog.log("Ability:creature_speak", "activating creature speak: level=%d range=%.0fm" % [_level, SPEAK_RANGE])

	# Raycast to find creature target
	var space := camera.get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_basis.z) * SPEAK_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 2  # World + NPCs
	var result: Dictionary = space.intersect_ray(query)

	if result.is_empty():
		DebugLog.log("Ability:creature_speak", "no creature in range")
		_spawn_fizzle_notes(from + (-camera.global_basis.z) * 2.0)
		return

	var hit_pos: Vector3 = result["position"]
	var hit_body: Object = result["collider"]
	DebugLog.log("Ability:creature_speak", "targeted: %s at %s" % [hit_body, hit_pos])

	# Phase 5/6: Check if hit_body is a speakable creature and open Dialogue Manager
	_spawn_musical_notes(hit_pos)

func _spawn_musical_notes(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 12
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.3
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.06
	pmesh.height = 0.06
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 45.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 2.5
	pmat.gravity = Vector3(0, 0.5, 0)  # Float upward
	pmat.color = Color(1.0, 0.9, 0.3)
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

func _spawn_fizzle_notes(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 5
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emitting = true
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.04
	pmesh.height = 0.04
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.spread = 90.0
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.0
	pmat.gravity = Vector3(0, 0.3, 0)
	pmat.color = Color(0.7, 0.7, 0.5, 0.5)
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
