@tool
extends Node2D
class_name Signpost

@export_multiline var text: String = "":
	set(value):
		text = value
		if is_instance_valid(text_label):
			text_label.text = text
@onready var sprite = $Sprite2D
@onready var interactable = $Interactable
@onready var text_panel = $MarginContainer
@onready var text_label = $MarginContainer/MarginContainer/Label
@onready var focus_label = $FocusLabel

@onready var outline_sprite = $OutlineSprite

var text_opened = false


func _on_focus_start():
	#sprite.modulate = Color(2, 2, 2, 1)
	outline_sprite.show()
	if not text_opened:
		focus_label.show()

func _on_focus_end():
	if text_opened:
		_close_text()
	focus_label.hide()
	#sprite.modulate = Color(1, 1, 1, 1)
	outline_sprite.hide()


func _on_interact():
	if text_opened:
		_close_text()
	else:
		_open_text()

func _open_text():
	_on_focus_end()
	text_opened = true
	text_panel.show()

func _close_text():
	text_opened = false
	text_panel.hide()
	_on_focus_start()

func _ready():
	if not Engine.is_editor_hint():
		text_panel.hide()
	text_label.text = text
	focus_label.hide()
	outline_sprite.hide()

 
