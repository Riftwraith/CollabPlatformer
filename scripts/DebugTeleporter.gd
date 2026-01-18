extends Node
class_name DebugTeleporter

# todo: automatically get list of debug points?
@export var teleport_locations: Array[DebugPoint]

var parent: Node2D

var prev_key: Key = KEY_NONE

func _teleport_to(debugPoint: DebugPoint) -> void:
	print_debug("teleporting to ", debugPoint.global_position)
	parent.global_position = debugPoint.global_position
	if parent.has_method("respawn"):
		parent.play_respawn_feedback()
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	if teleport_locations.is_empty():
		push_warning("teleport locations not assigned!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_CTRL):
		for n in range(teleport_locations.size()):
			assert(n < 9, "debug tp only supports key_1 through key_9")
			var key = KEY_1 + n as Key
			if prev_key == key and !Input.is_key_pressed(prev_key):
				# tp on key release
				_teleport_to(teleport_locations[n])
				prev_key = KEY_NONE
			if Input.is_key_pressed(key):
				prev_key = key
				pass
	pass
