class_name FireAbility
extends AbilityBase
## Launches a fireball projectile from the player's view direction.
## Higher levels → more damage, larger blast radius, shorter cooldown.

const FIREBALL_SPEED: float = 20.0
const FIREBALL_LIFETIME: float = 3.0
const BASE_DAMAGE: float = 10.0
const BASE_BLAST_RADIUS: float = 1.5

func _init() -> void:
	discipline = "fire"
	cooldown = 2.0

func _execute(camera: Camera3D) -> void:
	var damage: float = BASE_DAMAGE * _level
	var blast_radius: float = BASE_BLAST_RADIUS + (_level - 1) * 0.5
	DebugLog.log("Ability:fire", "launching fireball: damage=%.0f blast_radius=%.1f" % [damage, blast_radius])

	var fireball := _create_fireball(camera)
	camera.get_tree().current_scene.add_child(fireball)
	fireball.global_position = camera.global_position + camera.global_basis * Vector3(0, 0, -1.0)

	var direction: Vector3 = -camera.global_basis.z
	_launch_fireball(fireball, direction, damage, blast_radius)

func _create_fireball(camera: Camera3D) -> RigidBody3D:
	var fireball := RigidBody3D.new()
	fireball.name = "Fireball"
	fireball.gravity_scale = 0.3
	fireball.collision_layer = 0
	fireball.collision_mask = 1

	# Collision shape
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	var col := CollisionShape3D.new()
	col.shape = shape
	fireball.add_child(col)

	# Visual — orange sphere
	var mesh := SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.0)
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	fireball.add_child(mesh_inst)

	# Particles
	var particles := GPUParticles3D.new()
	particles.amount = 20
	particles.lifetime = 0.4
	particles.emitting = true
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.03
	pmesh.height = 0.06
	particles.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0, 1)
	pmat.spread = 30.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 2.0
	pmat.gravity = Vector3.ZERO
	pmat.color = Color(1.0, 0.5, 0.1)
	particles.process_material = pmat
	fireball.add_child(particles)

	# OmniLight
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.1)
	light.light_energy = 2.0
	light.omni_range = 3.0
	fireball.add_child(light)

	return fireball

func _launch_fireball(fireball: RigidBody3D, direction: Vector3, damage: float, blast_radius: float) -> void:
	fireball.linear_velocity = direction * FIREBALL_SPEED

	# Self-destruct timer
	var timer := Timer.new()
	timer.wait_time = FIREBALL_LIFETIME
	timer.one_shot = true
	timer.autostart = true
	fireball.add_child(timer)
	timer.timeout.connect(func() -> void:
		DebugLog.log("Ability:fire", "fireball expired (no impact)")
		_spawn_impact_effect(fireball.global_position, blast_radius)
		fireball.queue_free()
	)

	# Body collision detection
	fireball.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("Player") or body.name == "CatPlayer":
			return
		DebugLog.log("Ability:fire", "fireball hit: %s (damage=%.0f)" % [body.name, damage])
		_spawn_impact_effect(fireball.global_position, blast_radius)
		fireball.queue_free()
	)
	fireball.contact_monitor = true
	fireball.max_contacts_reported = 4

func _spawn_impact_effect(pos: Vector3, radius: float) -> void:
	DebugLog.log("Ability:fire", "impact at %s, blast_radius=%.1f" % [pos, radius])
	var burst := GPUParticles3D.new()
	burst.amount = 30
	burst.lifetime = 0.6
	burst.one_shot = true
	burst.emitting = true
	burst.explosiveness = 1.0
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.05
	pmesh.height = 0.1
	burst.draw_pass_1 = pmesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 3.0
	pmat.initial_velocity_max = 6.0
	pmat.gravity = Vector3(0, -5, 0)
	pmat.color = Color(1.0, 0.3, 0.0)
	burst.process_material = pmat

	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(burst)
		burst.global_position = pos
		# Auto-free after particles finish
		var cleanup_timer := Timer.new()
		cleanup_timer.wait_time = 1.0
		cleanup_timer.one_shot = true
		cleanup_timer.autostart = true
		burst.add_child(cleanup_timer)
		cleanup_timer.timeout.connect(burst.queue_free)
