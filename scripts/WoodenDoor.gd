extends Node2D
class_name WoodenDoor

enum StatusEnum {OPEN, CLOSED}
@export var status: StatusEnum = StatusEnum.CLOSED

@onready var collision_shape = $StaticBody2D/CollisionShape2D
@onready var anim_sprite = $AnimatedSprite2D
@onready var sprite_mat = anim_sprite.material
@onready var focus_label = $FocusLabel



func _ready():
	match status:
		StatusEnum.OPEN:
			anim_sprite.animation = "opening"
			anim_sprite.frame = 2
			collision_shape.set_deferred("disabled", true)
			focus_label.text = "x: Close"
		StatusEnum.CLOSED:
			anim_sprite.animation = "closing"
			anim_sprite.frame = 2
			collision_shape.set_deferred("disabled", false)
			focus_label.text = "x: Open"
	focus_label.hide()
	sprite_mat.set("shader_parameter/outline_enabled", false) # off

func _on_interactable_focus_start():
	focus_label.show()
	sprite_mat.set("shader_parameter/outline_enabled", true)  # on


func _on_interactable_focus_end():
	focus_label.hide()
	sprite_mat.set("shader_parameter/outline_enabled", false) # off


func _on_interactable_interacted():
	match status:
		StatusEnum.OPEN:
			anim_sprite.play("closing")
			collision_shape.set_deferred("disabled", false)
			focus_label.text = "x: Open"
			status = StatusEnum.CLOSED
		StatusEnum.CLOSED:
			anim_sprite.play("opening")
			collision_shape.set_deferred("disabled", true)
			focus_label.text = "x: Close"
			status = StatusEnum.OPEN
