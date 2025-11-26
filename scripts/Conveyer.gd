@tool
extends Path2D

@onready var follower = $PathFollow2D
@onready var sprite_layer = $DisplaySprites

@export var display_sprite: Sprite2D

@export var travel_time: float = 4
@export var wait_time: float = 2
@export var easing_curve: Curve

var t: float = 0.0

var dir_forwards = true
enum {WAITING, MOVING}
var state = WAITING


func _create_display_sprite():
	var new_sprite = display_sprite.duplicate()
	sprite_layer.add_child(new_sprite)
	new_sprite.modulate = Color(1, 1, 1, 0.3)
	new_sprite.hide()

func _ready():
	if Engine.is_editor_hint():
		return
	sprite_layer.queue_free()
	#Reparent all children to the follower
	for child in get_children():
		if child != follower and child != sprite_layer:
			child.reparent(follower)


func _start_moving():
	t = 0.0
	state = MOVING

func _stop_moving():
	dir_forwards = not dir_forwards
	t = 0.0
	state = WAITING

func _physics_process(delta):
	if Engine.is_editor_hint():
		if is_instance_valid(curve):
			if curve.point_count > 0:
				curve.set_point_position(0, Vector2.ZERO)
		for child in get_children():
			child.position = Vector2.ZERO
		if display_sprite:
			for i in range(curve.point_count - sprite_layer.get_child_count()):
				_create_display_sprite()
			for child in sprite_layer.get_children():
				child.hide()
			for i in range(curve.point_count):
				var sprite = sprite_layer.get_child(i)
				sprite.position = curve.get_point_position(i)
				sprite.show()
		return
	match state:
		WAITING: 
			t += delta
			if t >= wait_time:
				_start_moving()
		MOVING:
			t += delta
			var progress_ratio = clamp(easing_curve.sample_baked(t / travel_time), 0.0, 1.0)
			if dir_forwards:
				follower.progress_ratio = progress_ratio
			else:
				follower.progress_ratio = 1.0 - progress_ratio
			
			if progress_ratio >= 1.0:
				_stop_moving()
