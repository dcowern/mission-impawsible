# autoloads/signal_bus.gd
extends Node

signal ability_unlocked(ability_name: String, level: int)
signal ability_used(ability_name: String, target: Node)
signal tuna_coins_changed(old_amount: int, new_amount: int)
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)
signal player_entered_area(area_name: String)
signal npc_interaction_started(npc_id: String)
signal npc_interaction_ended(npc_id: String)
signal day_night_changed(is_day: bool)
signal magic_discipline_discovered(discipline: String)
