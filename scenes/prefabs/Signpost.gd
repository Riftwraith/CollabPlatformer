extends Node2D
class_name Signpost

@export var text: String = ""
@onready var sprite = $Sprite2D
@onready var interactable = $Interactable
@onready var text_panel = $TextPanel
@onready var text_label = $TextPanel/Label
@onready var focus_label = $FocusLabel

var text_opened = false


func _on_focus_start():
	sprite.modulate = Color(2, 2, 2, 1)
	if not text_opened:
		focus_label.show()

func _on_focus_end():
	if text_opened:
		_close_text()
	focus_label.hide()
	sprite.modulate = Color(1, 1, 1, 1)


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
	text_panel.hide()
	text_label.text = text
	focus_label.hide()
	

 
