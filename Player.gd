extends CharacterBody2D

@export var run_speed: float = 150
@export var air_speed: float = 150 #max speed
@export var air_accel: float = 400
@export var jump_speed: float = 420
@export var gravity: float = 900
@export var coyote_time: float = 0.1

@export var control_enabled = true
@export var gravity_enabled = true

@onready var anim_sprite = $AnimatedSprite2D
var facing_left = false

func _ready():
	anim_sprite.play()
	$CoyoteTimer.wait_time = coyote_time

func is_on_safe_ground():
	if not is_on_floor(): return false
	if $FloorRayCasts/FrontRay.is_colliding() and $FloorRayCasts/BackRay.is_colliding():
		return true
	return false

func _read_movement_inputs() -> Vector2:
	var move_vec = Vector2.ZERO
	if Input.is_action_pressed("left"):
		move_vec += Vector2.LEFT
	if Input.is_action_pressed("right"):
		move_vec += Vector2.RIGHT
	if Input.is_action_just_pressed("jump"):
		_jump()
	return move_vec

func _jump():
	if is_on_floor():
		velocity.y -= jump_speed
		$Sounds/Jump.play()


func _process(delta):
	var move_vec = _read_movement_inputs() 

	
	if is_on_floor():
		#ground movement
		velocity.x = move_vec.x * run_speed 
	else:
		#air_movement has momentum:
		var target_vx = move_vec.x * air_speed
		velocity.x = velocity.x + clamp(target_vx - velocity.x, -1 * air_accel * delta, air_accel * delta)
		#clamp(velocity.x + (move_vec.x * air_accel * delta), -1 * air_speed, air_speed)
		if gravity_enabled:
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
	
	
	
