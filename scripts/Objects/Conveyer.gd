@tool
extends Path2D
class_name Conveyor

@onready var _follower = $PathFollow2D
@onready var _sprite_layer = $DisplaySprites

@export var display_sprite: Sprite2D

@export var travel_time: float = 4
@export var wait_time: float = 2
@export var easing_curve: Curve

@export var active: bool = true

enum {WAITING, MOVING}
var _dir_forwards: bool = true
var _state = WAITING
var _t: float = 0.0


func _create_display_sprite():
	var new_sprite = display_sprite.duplicate()
	_sprite_layer.add_child(new_sprite)
	new_sprite.modulate = Color(1, 1, 1, 0.3)
	new_sprite.hide()

func _ready():
	if Engine.is_editor_hint():
		return
	_sprite_layer.queue_free()
	
	# Reparent all children to the follower
	for child in get_children():
		if child != _follower and child != _sprite_layer:
			child.reparent(_follower)


func _start_moving():
	_t = 0.0
	_state = MOVING

func _stop_moving():
	_dir_forwards = not _dir_forwards
	_t = 0.0
	_state = WAITING

func _physics_process(delta):
	if not active: return
	if Engine.is_editor_hint():
		if is_instance_valid(curve):
			if curve.point_count > 0:
				curve.set_point_position(0, Vector2.ZERO)
		for child in get_children():
			child.position = Vector2.ZERO
		if display_sprite:
			for i in range(curve.point_count - _sprite_layer.get_child_count()):
				_create_display_sprite()
			for child in _sprite_layer.get_children():
				child.hide()
			for i in range(curve.point_count):
				var sprite = _sprite_layer.get_child(i)
				sprite.position = curve.get_point_position(i)
				sprite.show()
		return
	match _state:
		WAITING:
			_t += delta
			if _t >= wait_time:
				_start_moving()
		MOVING:
			_t += delta
			var progress_ratio = clamp(easing_curve.sample_baked(_t / travel_time), 0.0, 1.0)
			if _dir_forwards:
				_follower.progress_ratio = progress_ratio
			else:
				_follower.progress_ratio = 1.0 - progress_ratio
			
			if progress_ratio >= 1.0:
				_stop_moving()
