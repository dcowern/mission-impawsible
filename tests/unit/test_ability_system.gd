extends GutTest
## Tests for the ability system — from PRD Phase 4.8.

var ability: AbilityBase

func before_each():
	GameState.reset()
	ability = AbilityBase.new()
	ability.discipline = "fire"
	ability.cooldown = 1.0
	add_child_autofree(ability)

func test_cannot_use_locked_ability():
	assert_false(ability.can_use(), "Level 0 ability should not be usable")

func test_can_use_after_unlock():
	GameState.unlock_ability("fire")
	# Force the ability to pick up the new level
	ability._on_ability_unlocked("fire", 1)
	assert_true(ability.can_use(), "Level 1 ability should be usable")

func test_cooldown_prevents_use():
	GameState.unlock_ability("fire")
	ability._on_ability_unlocked("fire", 1)
	ability._cooldown_timer = 0.5  # simulate mid-cooldown
	assert_false(ability.can_use(), "Should not use during cooldown")

func test_level_scales_with_unlocks():
	GameState.add_tuna_coins(3)  # now 5 coins
	GameState.unlock_ability("fire")
	GameState.unlock_ability("fire")
	GameState.unlock_ability("fire")
	assert_eq(GameState.get_ability_level("fire"), 3)

func test_cooldown_percent():
	ability._on_ability_unlocked("fire", 1)
	ability._cooldown_timer = 0.5
	# cooldown is 1.0, so 50% remaining
	assert_almost_eq(ability.get_cooldown_percent(), 0.5, 0.01)

func test_cooldown_percent_when_ready():
	ability._on_ability_unlocked("fire", 1)
	ability._cooldown_timer = 0.0
	assert_eq(ability.get_cooldown_percent(), 0.0)

func test_different_disciplines_independent():
	var ice_ability := AbilityBase.new()
	ice_ability.discipline = "ice"
	ice_ability.cooldown = 2.0
	add_child_autofree(ice_ability)

	GameState.add_tuna_coins(3)
	GameState.unlock_ability("fire")
	GameState.unlock_ability("ice")

	ability._on_ability_unlocked("fire", 1)
	ice_ability._on_ability_unlocked("ice", 1)

	assert_true(ability.can_use(), "Fire should be usable")
	assert_true(ice_ability.can_use(), "Ice should be usable")

	# Put fire on cooldown
	ability._cooldown_timer = 0.5
	assert_false(ability.can_use(), "Fire on cooldown")
	assert_true(ice_ability.can_use(), "Ice still ready")

func test_ability_unlocked_signal_updates_level():
	assert_eq(ability._level, 0)
	ability._on_ability_unlocked("fire", 2)
	assert_eq(ability._level, 2)

func test_wrong_discipline_signal_ignored():
	ability._on_ability_unlocked("ice", 1)
	assert_eq(ability._level, 0, "Fire ability should ignore ice unlock")
