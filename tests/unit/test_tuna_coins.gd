extends GutTest
## Tests for tuna coin economy — from PRD Phase 3.5.

func before_each():
	GameState.reset()

func test_pickup_adds_coins():
	# Simulate coin pickup
	GameState.add_tuna_coins(1)
	assert_eq(GameState.tuna_coins, 3, "2 starting + 1 pickup = 3")

func test_unlock_spend_cycle():
	GameState.add_tuna_coins(3)  # now 5 total
	GameState.unlock_ability("fire")    # costs 1 → 4
	GameState.unlock_ability("fire")    # costs 1 → 3 (fire level 2)
	GameState.unlock_ability("ice")     # costs 1 → 2
	assert_eq(GameState.tuna_coins, 2)
	assert_eq(GameState.get_ability_level("fire"), 2)
	assert_eq(GameState.get_ability_level("ice"), 1)

func test_signal_emitted_on_coin_change():
	# Use watch_signals to track signal emissions
	watch_signals(SignalBus)
	GameState.add_tuna_coins(1)
	assert_signal_emitted(SignalBus, "tuna_coins_changed", "Signal should fire on coin change")
	var params = get_signal_parameters(SignalBus, "tuna_coins_changed")
	assert_eq(params[0], 2, "old value should be 2")
	assert_eq(params[1], 3, "new value should be 3")

func test_cannot_unlock_with_no_coins():
	GameState.tuna_coins = 0
	var result := GameState.unlock_ability("fire")
	assert_false(result, "Should fail to unlock with 0 coins")
	assert_eq(GameState.get_ability_level("fire"), 0, "Fire should remain locked")

func test_invalid_discipline_fails():
	var result := GameState.unlock_ability("telekinesis")
	assert_false(result, "Invalid discipline should fail")
	assert_push_error(1, "Should have 1 push_error for invalid discipline")

func test_coins_cannot_go_negative():
	GameState.tuna_coins = 0
	GameState.add_tuna_coins(-5)
	assert_eq(GameState.tuna_coins, 0, "Coins should not go below 0")

func test_ability_unlocked_signal():
	watch_signals(SignalBus)
	GameState.unlock_ability("woodland")
	assert_signal_emitted(SignalBus, "ability_unlocked", "ability_unlocked signal should fire")
	var params = get_signal_parameters(SignalBus, "ability_unlocked")
	assert_eq(params[0], "woodland")
	assert_eq(params[1], 1)

func test_multiple_disciplines_independent():
	GameState.add_tuna_coins(5)  # 7 total
	GameState.unlock_ability("fire")
	GameState.unlock_ability("ice")
	GameState.unlock_ability("woodland")
	GameState.unlock_ability("dragon_taming")
	GameState.unlock_ability("creature_speak")
	for discipline in GameState.MAGIC_DISCIPLINES:
		assert_eq(GameState.get_ability_level(discipline), 1, "%s should be level 1" % discipline)
	assert_eq(GameState.tuna_coins, 2, "Should have 2 coins remaining")
