@tool
extends Node2D
class_name Signpost

@export_multiline var text: String = "":
	set(value):
		text = value
		if is_instance_valid(text_label):
			text_label.text = text
@onready var sprite = $Sprite2D
@onready var sprite_mat = sprite.material
@onready var interactable = $Interactable
@onready var text_panel = $MarginContainer
@onready var text_label = $MarginContainer/MarginContainer/Label
@onready var focus_label = $FocusLabel

var text_opened = false


func _on_focus_start():
	if not text_opened:
		focus_label.show()
	sprite_mat.set("shader_parameter/outline_enabled", true) # on

func _on_focus_end():
	if text_opened:
		_close_text()
	focus_label.hide()
	sprite_mat.set("shader_parameter/outline_enabled", false) # off


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
	sprite_mat.set("shader_parameter/outline_enabled", false) # off

 
