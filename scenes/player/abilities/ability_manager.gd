class_name AbilityManager
extends Node
## Manages the 5 ability nodes for the player.
## Creates ability instances and connects them to the AbilityHUD.

var abilities: Array[AbilityBase] = []

func _ready() -> void:
	# Create one ability node per discipline
	var fire := FireAbility.new()
	var ice := IceAbility.new()
	var woodland := WoodlandAbility.new()
	var dragon := DragonTamingAbility.new()
	var speak := CreatureSpeakAbility.new()

	abilities = [fire, ice, woodland, dragon, speak]

	for ability in abilities:
		add_child(ability)

	DebugLog.log("AbilityManager", "initialized %d abilities" % abilities.size())

	# Connect to HUD if it exists
	_connect_hud.call_deferred()

func _connect_hud() -> void:
	# Find AbilityHUD in the scene tree
	var hud := _find_ability_hud(get_tree().current_scene)
	if hud and hud.has_method("set_abilities"):
		hud.set_abilities(abilities)
		DebugLog.log("AbilityManager", "connected to AbilityHUD")
	else:
		DebugLog.log("AbilityManager", "no AbilityHUD found — abilities work without HUD")

func _find_ability_hud(node: Node) -> Node:
	if node == null:
		return null
	if node.name == "AbilityHUD":
		return node
	for child in node.get_children():
		var result := _find_ability_hud(child)
		if result:
			return result
	return null

func get_ability(discipline: String) -> AbilityBase:
	for ability in abilities:
		if ability.discipline == discipline:
			return ability
	return null
