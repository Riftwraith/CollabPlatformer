extends Node2D
class_name Collectable

@export var oscillate_amplitude: float = 10.0
@export var oscillate_period: float = 3.0

@onready var sprite = $Sprite2D
@onready var sound_collect = $Audio/Collect
@onready var collision_area = $Area2D

var t: float = 0

signal obtained 

func _process(delta):
	t += delta
	if t > oscillate_period: t = t - oscillate_period
	sprite.position.y = oscillate_amplitude * sin(TAU * t / oscillate_period)

func _on_area_2d_body_entered(body: Node2D):
	obtained.emit(self, body)
	hide()
	collision_area.queue_free()
	sound_collect.play()
	
	await sound_collect.finished
	
	queue_free()

	
