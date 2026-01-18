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
var _enabled: bool = false
var _initialized: bool = false
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
	if !_enabled:
		return
		
	_update_ai()
	if is_on_floor():
		velocity.x = _horizontal_velocity

	gravity.apply_gravity(delta)
	move_and_slide()

func _process(_delta: float) -> void:
	_first_proc()
	
	_update_graphics()
	if !_enabled:
		return
		
	_prev_direction = direction

#endregion

#region Private Functions

func _first_proc() -> void:
	if _initialized:
		return
	_setup_player_signals()
	_enabled = true
	_initialized = true
	
func _update_ai() -> void:
	match ai_mode:
		AIMode.Fall, AIMode.AvoidFalling:
			if is_on_wall():
				turn()

func _update_graphics() -> void:
	sprite.flip_h = direction != Direction.Right
	if !_enabled:
		sprite.stop()
		return
		
	if velocity.x != 0:
		sprite.play("walk")
	

func _setup_fall_signals() -> void:
	for dir in Direction.values():
		sensors[dir].body_exited.connect(func(_collider):
			if dir == direction and is_on_floor():
				turn())

func _setup_player_signals() -> void:
	# search for room
	var node = get_parent()
	while node:
		if node as RoomTemplate:
			break
		node = node.get_parent()

	if !node:
		push_warning("Could not find RoomTemplate!")
		return
		
	var room: RoomTemplate = node as RoomTemplate
	var player: Player = room.player
	player.death_begin.connect(_on_player_death)
	player.spawn_end.connect(_on_player_spawn)

func _on_player_death() -> void:
	_enabled = false
	
func _on_player_spawn() -> void:
	_enabled = true

#endregion
