extends GutTest

func before_each():
	GameState.reset()

func test_initial_tuna_coins():
	assert_eq(GameState.tuna_coins, 2, "Player starts with 2 tuna coins per lore")

func test_unlock_ability_spends_coin():
	GameState.unlock_ability("fire")
	assert_eq(GameState.tuna_coins, 1, "Should have 1 coin after unlocking fire")
	assert_eq(GameState.get_ability_level("fire"), 1, "Fire should be level 1")

func test_unlock_ability_fails_without_coins():
	GameState.tuna_coins = 0
	var result := GameState.unlock_ability("ice")
	assert_false(result, "Should fail to unlock without coins")
	assert_eq(GameState.get_ability_level("ice"), 0, "Ice should still be level 0")

func test_unlock_invalid_discipline_fails():
	var result := GameState.unlock_ability("laser_eyes")
	assert_false(result, "Should reject invalid discipline")
	assert_eq(GameState.tuna_coins, 2, "Coins should be unchanged")
	assert_push_error("invalid discipline")

func test_all_five_disciplines_exist():
	var expected := ["fire", "ice", "woodland", "dragon_taming", "creature_speak"]
	for d in expected:
		assert_has(GameState.ability_levels, d, "Discipline %s should exist" % d)

func test_add_tuna_coins():
	GameState.add_tuna_coins(3)
	assert_eq(GameState.tuna_coins, 5, "Should have 2 + 3 = 5 coins")

func test_tuna_coins_cannot_go_negative():
	GameState.tuna_coins = 0
	GameState.tuna_coins = -5
	assert_eq(GameState.tuna_coins, 0, "Coins should not go below 0")
