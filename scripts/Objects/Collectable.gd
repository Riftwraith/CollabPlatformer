extends Node2D
class_name Collectable

@export var oscillate_amplitude: float = 10.0
@export var oscillate_period: float = 3.0

@onready var _anim_sprite = $AnimatedSprite2D
@onready var _sound_collect = $Audio/Collect
@onready var _collision_area = $Area2D

var _t: float = 0

signal obtained

func _process(delta):
	_anim_sprite.play()
	_t += delta
	if _t > oscillate_period:
		_t = _t - oscillate_period
	_anim_sprite.position.y = oscillate_amplitude * sin(TAU * _t / oscillate_period)

func _on_area_2d_body_entered(body: Node2D):
	obtained.emit(self, body)
	hide()
	_collision_area.queue_free()
	_sound_collect.play()
	
	await _sound_collect.finished
	
	queue_free()
