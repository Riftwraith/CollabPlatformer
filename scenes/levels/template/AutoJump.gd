extends Node2D
class_name AutoJump

@export var timer_delay_seconds: float = 2.0

@onready var label: Label = $Label

var _timer: Timer = Timer.new()
var _player: Player
var jump_counter: int = 0

func _ready() -> void:
	_player = get_parent()
	assert(_player as Player)
	
	_player.on_jump.connect(func():
		jump_counter += 1
		label.text = str(jump_counter)
		)
	
	add_child(_timer) # add the timer to the scene
	_timer.start(timer_delay_seconds)
	_timer.timeout.connect(func():
		_player._queue_jump()
		_timer.start(timer_delay_seconds)
	)
