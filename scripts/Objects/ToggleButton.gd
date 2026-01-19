extends Node2D
class_name ToggleButton
#Eg for elevators

@export var toggle_target: Node2D 
@export var target_property: String #Must be bool
@export var sprite: Node2D

@onready var sprite_mat = sprite.material
@onready var focus_label = $FocusLabel
@onready var audio_player = $AudioStreamPlayer2D


func _ready():
	focus_label.hide()
	sprite_mat.set("shader_parameter/outline_enabled", false) # off

func _on_interactable_focus_start():
	focus_label.show()
	sprite_mat.set("shader_parameter/outline_enabled", true)  # on

func _on_interactable_focus_end():
	focus_label.hide()
	sprite_mat.set("shader_parameter/outline_enabled", false) # off

func _on_interactable_interacted():
	toggle_target.set(target_property, not toggle_target.get(target_property))
	audio_player.play()
