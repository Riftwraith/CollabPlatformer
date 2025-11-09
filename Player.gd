extends CharacterBody2D
class_name Player

@export var run_speed: float = 150
@export var air_speed: float = 150
@export var jump_height: int = 98 #in pixels
@export var gravity: float = 900
@export var coyote_time: float = 0.1
@export var jump_queue_time: float = 0.1

@export var control_enabled = true
@export var gravity_enabled = true

@onready var anim_sprite = $AnimatedSprite2D
var anim_busy = false #lock animation (eg for respawning)

var jump_speed: float
var jumping_up = false #flag if releasing "jump" should reduce velocity.y

var current_focus = null #current interactable object

func _ready():
	jump_speed = sqrt(2*jump_height*gravity)
	anim_sprite.play()

func is_on_safe_ground():
	if not is_on_floor(): return false
	if $FloorRayCasts/FrontRay.is_colliding() and $FloorRayCasts/BackRay.is_colliding():
		return true
	return false

func _read_inputs() -> Vector2:
	var move_vec = Vector2.ZERO
	if Input.is_action_pressed("left"):
		move_vec += Vector2.LEFT
	if Input.is_action_pressed("right"):
		move_vec += Vector2.RIGHT
	if Input.is_action_just_pressed("jump"):
		_queue_jump()
	if Input.is_action_just_released("jump"):
		if jumping_up:
			velocity.y = 0.5 * velocity.y #limit jump height
			jumping_up = false
	if Input.is_action_just_pressed("interact"):
		var interactable =  _get_closest_interactable()
		if interactable != null:
			interactable.interact(self)
	return move_vec

func _queue_jump():
	#can press jump key when just about to land 
	$JumpQueueTimer.start(jump_queue_time)

func _execute_jump():
	$JumpQueueTimer.stop()
	$CoyoteTimer.stop()
	velocity.y = -1 * jump_speed
	jumping_up = true


func _process(delta):
	var move_vec = Vector2.ZERO
	if control_enabled: 
		move_vec = _read_inputs() 

	if is_on_floor():
		#ground movement
		velocity.x = move_vec.x * run_speed 
		if not $JumpQueueTimer.is_stopped():
			_execute_jump()
		$CoyoteTimer.start(coyote_time)
	else:
		#air movement
		velocity.x = move_vec.x * air_speed 
		#If you walk off a ledge, you can still jump within a certain window
		if not $CoyoteTimer.is_stopped() and not $JumpQueueTimer.is_stopped():
			_execute_jump()
		if gravity_enabled:
			velocity.y += gravity * delta
	#if player falling, can't release jump to reduce velocity.y
	if jumping_up:
		if velocity.y >= 0:
			jumping_up = false
	
	#focus on interactable objects (eg for highlighting them)
	var focus = _get_closest_interactable() #may be null
	if focus != current_focus:
		if is_instance_valid(current_focus):
			if current_focus.has_method("end_focus"):
				current_focus.end_focus(self)
		if is_instance_valid(focus):
			if focus.has_method("start_focus"):
				focus.start_focus(self)
	current_focus = focus


func _flash_white():
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", Color(2, 2, 2, 1), 0.05)
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1,), 0.10)
	tween.tween_property(anim_sprite, "modulate", Color(2, 2, 2, 1,), 0.15)
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1,), 0.20)

func _get_closest_interactable():
	var closest = null
	for object in ($InteractArea.get_overlapping_areas() + $InteractArea.get_overlapping_bodies()):
		if not object.has_method("interact"): continue
		if closest == null:
			closest = object
		elif (object.global_position - global_position) < (closest.global_position - global_position):
			closest = object
	return closest

func respawn():
	velocity = Vector2.ZERO
	control_enabled = false
	anim_busy = true
	anim_sprite.animation = "respawn"
	_flash_white()
	await anim_sprite.animation_finished
	control_enabled = true
	anim_busy = false

func _set_movement_anim():
	anim_sprite.play()
	if abs(velocity.x) > 0:
		anim_sprite.animation = "run"
	else:
		anim_sprite.animation = "idle"
	
	if velocity.y < 0:
		anim_sprite.animation = "jump"
	if velocity.y > 0:
		anim_sprite.animation = "fall"

func _physics_process(delta):
	if abs(velocity.x) > 0:
		anim_sprite.flip_h = (velocity.x < 0)
	
	if not anim_busy:
		_set_movement_anim()

	#this function adds velocity * delta to position & automatically handles collision
	move_and_slide()
	
	# Very janky push physics for rigidbody2d 
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody2D: #pushable
			var coll_speed = (collision.get_travel() + collision.get_remainder()).length() / delta
			var push_dir = -1 * collision.get_normal()
			var push_strength = 0.01 * coll_speed
			collider.apply_impulse(push_dir * push_strength, collision.get_position() - collider.global_position)
