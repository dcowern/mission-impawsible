extends GutTest
## Tests for NPC base class and NPC types — Phase 5.

var npc: NPCBase

func before_each():
	GameState.reset()
	npc = NPCBase.new()
	npc.npc_id = "test_npc"
	npc.creature_type = "cat"
	add_child_autofree(npc)

func test_npc_initializes_in_idle():
	assert_eq(npc.current_state, NPCBase.State.IDLE)

func test_npc_has_collision():
	var col := npc.get_node_or_null("CollisionShape3D")
	assert_not_null(col, "NPC should have a CollisionShape3D")

func test_npc_has_placeholder_model():
	var model := npc.get_node_or_null("PH_Model")
	assert_not_null(model, "NPC should have placeholder model when no model_scene set")

func test_npc_has_label():
	var found_label := false
	for child in npc.get_children():
		if child is Label3D:
			found_label = true
			break
	assert_true(found_label, "NPC should have a Label3D identifier")

func test_npc_state_change():
	npc._change_state(NPCBase.State.WANDER)
	assert_eq(npc.current_state, NPCBase.State.WANDER)

func test_npc_taming_dragon():
	var dragon := DragonNPC.new()
	dragon.npc_id = "test_dragon"
	add_child_autofree(dragon)
	assert_false(dragon.tamed)
	dragon.apply_taming()
	assert_true(dragon.tamed)
	assert_eq(dragon.current_state, NPCBase.State.TAMED)

func test_npc_taming_non_dragon_fails():
	npc.apply_taming()
	assert_false(npc.tamed, "Cat should not be tameable")
	assert_ne(npc.current_state, NPCBase.State.TAMED)

func test_cat_npc_type():
	var cat := CatNPC.new()
	cat.npc_id = "test_cat"
	add_child_autofree(cat)
	assert_eq(cat.creature_type, "cat")
	assert_false(cat.can_speak)

func test_creature_npc_can_speak():
	var bird := CreatureNPC.new()
	bird.npc_id = "test_bird"
	bird.creature_type = "bird"
	add_child_autofree(bird)
	assert_true(bird.can_speak)
	assert_eq(bird.creature_type, "bird")

func test_dragon_npc_type():
	var dragon := DragonNPC.new()
	dragon.npc_id = "test_dragon2"
	add_child_autofree(dragon)
	assert_eq(dragon.creature_type, "dragon")
	assert_false(dragon.can_speak)

func test_save_state():
	npc.global_position = Vector3(10, 5, 20)
	npc.tamed = true
	var data: Dictionary = npc.save_state()
	assert_eq(data["npc_id"], "test_npc")
	assert_true(data["tamed"])

func test_load_state():
	var data := {"npc_id": "test_npc", "tamed": true, "position": var_to_str(Vector3(10, 5, 20))}
	npc.load_state(data)
	assert_true(npc.tamed)

func test_placeholder_colors():
	# Cat = magenta
	var cat := NPCBase.new()
	cat.creature_type = "cat"
	assert_eq(cat._get_placeholder_color(), Color(1.0, 0.0, 1.0))

	# Dragon = orange
	cat.creature_type = "dragon"
	assert_eq(cat._get_placeholder_color(), Color(1.0, 0.5, 0.0))

	# Bird = sky blue
	cat.creature_type = "bird"
	assert_eq(cat._get_placeholder_color(), Color(0.5, 0.8, 1.0))
