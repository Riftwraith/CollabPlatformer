@tool
extends Path2D

@onready var follower = $PathFollow2D
@onready var sprite_layer = $DisplaySprites

@export var display_sprite: Sprite2D

@export var travel_time: float = 4
@export var wait_time: float = 2

var t: float = 0.0

var freq: float = 0.0
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
	#Reparent all children to the follower
	for child in get_children():
		if child == follower: continue
		remove_child(child)
		follower.add_child(child)
		child.position = Vector2.ZERO
	freq = TAU / travel_time

func _start_moving():
	t = 0.0
	state = MOVING

func _stop_moving():
	dir_forwards = not dir_forwards
	t = 0.0
	state = WAITING

func _physics_process(delta):
	if Engine.is_editor_hint():
		if curve.point_count > 0:
			curve.set_point_position(0, Vector2.ZERO)
		position = Vector2.ZERO
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
			var progress_ratio = clamp(0.5 * (-1 * cos(freq * t) + 1), 0.0, 1.0)
			if dir_forwards:
				follower.progress_ratio = progress_ratio
			else:
				follower.progress_ratio = 1.0 - progress_ratio
			if progress_ratio >= 1.0:
				_stop_moving()
