extends CharacterBody2D

@export var run_speed: float = 150
@export var air_speed: float = 150
@export var jump_speed: float = 420
@export var gravity: float = 900

@export var control_enabled = true
@export var gravity_enabled = true

@onready var anim_sprite = $AnimatedSprite2D
var facing_left = false

func _ready():
	anim_sprite.play()


func _do_movement_controls():
	var move_vec = Vector2.ZERO
	if Input.is_action_pressed("left"):
		move_vec += Vector2.LEFT
	if Input.is_action_pressed("right"):
		move_vec += Vector2.RIGHT
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y -= jump_speed
	if is_on_floor():
		velocity.x = move_vec.x * run_speed 
	else:
		velocity.x = move_vec.x * air_speed

func _process(delta):
	
	if control_enabled:
		_do_movement_controls()
	
	if gravity_enabled:
		if not is_on_floor():
			velocity.y += gravity * delta
	
func _physics_process(delta):
	if abs(velocity.x) > 0:
		anim_sprite.flip_h = (velocity.x < 0)
	
	if abs(velocity.x) > 0:
		anim_sprite.animation = "run"
	else:
		anim_sprite.animation = "idle"
	
	move_and_slide()
	
	# Check collisions
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is RigidBody2D:
			# Apply a push impulse
			var push_dir = collider.position - position
			var push_strength = 10
			collider.apply_central_impulse(push_dir * push_strength * delta)
	
	
	
