extends CanvasLayer
## Scrollable credits screen. Displays attribution information.

signal closed

const CREDITS_TEXT := """[center][b]MISSION IMPAWSIBLE[/b][/center]

[center]A first-person adventure game about a cat with magical gem blood.[/center]

[center]---[/center]

[center][b]Godot Plugins[/b][/center]

[b]COGITO v1.1.5[/b] — Philip Drobar (MIT)
First-person immersive sim framework

[b]Terrain3D v1.0.1[/b] — TokisanGames (MIT)
GPU-driven procedural terrain

[b]Sky3D[/b] — TokisanGames (MIT)
Day/night cycle and atmosphere

[b]Boujie Water Shader[/b] — Zach Bernal (MIT)
Ocean and water rendering

[b]BehaviourToolkit[/b] — Patrick Selge (MIT)
NPC AI framework

[b]Dialogue Manager 3[/b] — Nathan Hoad (MIT)
Branching dialogue system

[b]GUT v9.5.0[/b] — bitwes (MIT)
Testing framework

[center]---[/center]

[center][b]3D Assets (CC0 Public Domain)[/b][/center]

[b]KayKit Medieval Hexagon Pack[/b] — Kay Lousberg
Buildings, props, and nature models

[b]KayKit Dungeon Remastered[/b] — Kay Lousberg
Shrine and dungeon props

[b]Kenney Nature Kit[/b] — Kenney Vleugels
Trees, bushes, flowers, and vegetation

[center]---[/center]

[center][b]Terrain Textures (CC0 Public Domain)[/b][/center]

All terrain textures from ambientCG.com

[center]---[/center]

[center][b]Built with Godot Engine 4.6[/b][/center]
[center]https://godotengine.org[/center]

[center]---[/center]

[center]Thank you for playing![/center]
"""

@onready var _panel: PanelContainer = $PanelContainer
@onready var _text: RichTextLabel = $PanelContainer/VBoxContainer/ScrollContainer/CreditsText
@onready var _close_btn: Button = $PanelContainer/VBoxContainer/CloseButton

func _ready() -> void:
	_panel.visible = false
	_text.text = CREDITS_TEXT
	_close_btn.pressed.connect(_on_close)

func open() -> void:
	_panel.visible = true
	DebugLog.log("Credits", "credits screen opened")

func _on_close() -> void:
	_panel.visible = false
	closed.emit()
	DebugLog.log("Credits", "credits screen closed")

func _input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("menu"):
		_on_close()
		get_viewport().set_input_as_handled()
