extends GutTest
## Tests for quest system — Phase 6.

var quest_mgr: QuestManager

func before_each():
	GameState.reset()
	quest_mgr = QuestManager.new()
	add_child_autofree(quest_mgr)

func test_main_quest_starts_not_started():
	assert_eq(quest_mgr.get_main_quest_stage(), "not_started")

func test_set_main_quest_stage():
	quest_mgr.set_main_quest_stage("awakening")
	assert_eq(quest_mgr.get_main_quest_stage(), "awakening")
	assert_eq(GameState.quest_flags["main_quest"], "awakening")

func test_advance_main_quest():
	quest_mgr.set_main_quest_stage("awakening")
	quest_mgr.advance_main_quest()
	assert_eq(quest_mgr.get_main_quest_stage(), "first_steps")

func test_advance_through_all_stages():
	var stages: Array = QuestManager.MAIN_QUEST_STAGES.keys()
	quest_mgr.set_main_quest_stage(stages[0])
	for i in range(stages.size() - 1):
		quest_mgr.advance_main_quest()
	assert_eq(quest_mgr.get_main_quest_stage(), "complete")

func test_main_quest_complete_sets_gem_found():
	quest_mgr.set_main_quest_stage("complete")
	assert_true(GameState.gem_found)

func test_quest_started_signal():
	watch_signals(SignalBus)
	quest_mgr.set_main_quest_stage("awakening")
	assert_signal_emitted(SignalBus, "quest_started")

func test_quest_completed_signal():
	watch_signals(SignalBus)
	quest_mgr.set_main_quest_stage("complete")
	assert_signal_emitted(SignalBus, "quest_completed")

func test_side_quest_default():
	assert_eq(quest_mgr.get_side_quest_stage("fetch_barrel"), "not_started")

func test_side_quest_progression():
	quest_mgr.set_side_quest_stage("fetch_barrel", "active")
	assert_eq(quest_mgr.get_side_quest_stage("fetch_barrel"), "active")
	quest_mgr.set_side_quest_stage("fetch_barrel", "complete")
	assert_true(quest_mgr.is_quest_complete("fetch_barrel"))

func test_active_quests():
	quest_mgr.set_main_quest_stage("awakening")
	quest_mgr.set_side_quest_stage("fetch_barrel", "active")
	var active: Array[String] = quest_mgr.get_active_quests()
	assert_true(active.has("main_quest"))
	assert_true(active.has("fetch_barrel"))

func test_invalid_main_stage_rejected():
	quest_mgr.set_main_quest_stage("nonexistent")
	assert_push_error(1)
	assert_eq(quest_mgr.get_main_quest_stage(), "not_started")

func test_invalid_side_quest_rejected():
	quest_mgr.set_side_quest_stage("nonexistent_quest", "active")
	assert_push_error(1)

func test_quest_persists_in_game_state():
	quest_mgr.set_main_quest_stage("first_steps")
	quest_mgr.set_side_quest_stage("tame_dragon", "active")
	# Verify quest_flags has both
	assert_eq(GameState.quest_flags["main_quest"], "first_steps")
	assert_eq(GameState.quest_flags["tame_dragon"], "active")
