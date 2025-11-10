extends Node
class_name DebugTeleporter

@export var teleport_locations: Array[Node2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(Key_CTRL):
		if Input.is_anything_pressed():
	pass
