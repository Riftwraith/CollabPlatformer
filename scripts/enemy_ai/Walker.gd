extends CharacterBody2D
class_name Walker

enum Direction {
	Right = 0,
	Left = 1,
}

enum AIMode {
	Fall,
	AvoidFalling,
}

# serialized state
@export var speed: float = 100.0
@export var initial_direction: Direction = Direction.Right
@export var ai_mode: AIMode = AIMode.Fall

# runtime state
@onready var direction: Direction = initial_direction

# components
@onready var sensors: Array[Area2D] = [ $RightFloorSensor, $LeftFloorSensor ]
@onready var gravity: GravityController = $GravityController
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# private state
@onready var _prev_direction = direction
var _horizontal_velocity: float:
	get:
		match direction:
			Direction.Right:
				return speed
			Direction.Left:
				return -speed
		assert(false, "invalid direction")
		return 0

func turn() -> void:
	direction = !direction as int as Direction
	

#region Godot Functions

func _ready() -> void:
	_update_graphics()
	if ai_mode == AIMode.AvoidFalling:
		_setup_fall_signals()

func _physics_process(delta: float) -> void:
	_update_ai()
	if is_on_floor():
		velocity.x = _horizontal_velocity

	gravity.apply_gravity(delta)
	move_and_slide()

func _process(_delta: float) -> void:
	if _prev_direction != direction:
		_update_graphics()
		
	_prev_direction = direction

#endregion

#region Private Functions

func _update_ai() -> void:
	match ai_mode:
		AIMode.Fall, AIMode.AvoidFalling:
			if is_on_wall():
				turn()

func _update_graphics() -> void:
	sprite.flip_h = direction != Direction.Right

func _setup_fall_signals() -> void:
	for dir in Direction.values():
		sensors[dir].body_exited.connect(func(collider):
			if dir == direction and is_on_floor():
				turn())
	

#endregion
