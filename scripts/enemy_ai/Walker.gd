extends CharacterBody2D
class_name Walker

enum Direction {
	Right = 0,
	Left = 1,
}

@export var speed: float = 100.0

var direction: Direction:
	get: 
		return Direction.Right

@onready var sensors: Array[Area2D] = [ $RightFloorSensor, $LeftFloorSensor ]

func _process(delta: float) -> void:
	#velocity.x = speed
	pass
