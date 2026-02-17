extends CanvasLayer
## Simple dialogue balloon UI for displaying Dialogue Manager lines.

signal dialogue_finished

@onready var _panel: PanelContainer = $Panel
@onready var _speaker_label: Label = $Panel/VBoxContainer/SpeakerLabel
@onready var _text_label: RichTextLabel = $Panel/VBoxContainer/DialogueText
@onready var _responses_container: VBoxContainer = $Panel/VBoxContainer/ResponsesContainer

var _dialogue_resource: Resource = null
var _is_showing: bool = false

func _ready() -> void:
	_panel.visible = false
	DebugLog.log("DialogueBalloon", "initialized")

func show_dialogue_line(speaker: String, text: String, responses: Array = []) -> void:
	_speaker_label.text = speaker
	_text_label.text = text
	_panel.visible = true
	_is_showing = true

	# Clear old responses
	for child in _responses_container.get_children():
		child.queue_free()

	if responses.size() > 0:
		for i in range(responses.size()):
			var btn := Button.new()
			btn.text = responses[i]
			var idx: int = i
			btn.pressed.connect(func() -> void: _on_response_selected(idx))
			_responses_container.add_child(btn)
	else:
		# Click to continue
		_responses_container.visible = false

	DebugLog.log("DialogueBalloon", "showing: [%s] %s" % [speaker, text.substr(0, 50)])

func hide_dialogue() -> void:
	_panel.visible = false
	_is_showing = false
	dialogue_finished.emit()
	DebugLog.log("DialogueBalloon", "dialogue hidden")

func _input(event: InputEvent) -> void:
	if not _is_showing:
		return
	if _responses_container.get_child_count() == 0:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			hide_dialogue()
			get_viewport().set_input_as_handled()

func _on_response_selected(index: int) -> void:
	DebugLog.log("DialogueBalloon", "response selected: %d" % index)
	hide_dialogue()
