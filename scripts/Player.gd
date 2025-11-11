extends CharacterBody2D
class_name Player


@export var run_speed: float = 150
@export var air_speed: float = 150
@export var jump_height: int = 98 #in pixels
@export var gravity: float = 900
@export var coyote_time: float = 0.1
@export var jump_queue_time: float = 0.1
@export var drop_timeout: float = 0.25

@export var control_enabled: bool = true
@export var gravity_enabled: bool = true

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_initial_scale: Vector2 = anim_sprite.scale
@onready var jump_queue_timer: Timer = $JumpQueueTimer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var front_ray: RayCast2D = $FloorRayCasts/FrontRay
@onready var back_ray: RayCast2D = $FloorRayCasts/BackRay

var anim_busy: bool = false #lock animation (eg for respawning)

var jump_speed: float
var jumping_up: bool = false #flag if releasing "jump" should reduce velocity.y

var current_focus: Interactable = null #current interactable object

func _ready():
	jump_speed = sqrt(2*jump_height*gravity)
	anim_sprite.play()

var is_on_safe_ground: bool:
	get:
		if not is_on_floor():
			return false
		if front_ray.is_colliding() and back_ray.is_colliding():
			return true
		return false

func _read_inputs() -> Vector2:
	var move_vec = Vector2.ZERO
	if !control_enabled:
		return move_vec
		
	if Input.is_action_pressed("left"):
		move_vec += Vector2.LEFT
	if Input.is_action_pressed("right"):
		move_vec += Vector2.RIGHT
		
	
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("down"):
			_drop_from_platform()
		else:
			_queue_jump()
	if Input.is_action_just_released("jump"):
		if jumping_up and velocity.y <= 0:
			velocity.y = 0.5 * velocity.y #limit jump height
			jumping_up = false
	if Input.is_action_just_pressed("interact"):
		var interactable =  _get_closest_interactable()
		if interactable != null:
			interactable.interact(self)
	return move_vec

func _queue_jump():
	#can press jump key when just about to land 
	jump_queue_timer.start(jump_queue_time)

# returns true if a jump was successfully done
# false if the jump failed (eg. jump cooldown not exceeded)
func _jump() -> bool:
	if jump_queue_timer.is_stopped():
		return false
	
	jump_queue_timer.stop()
	coyote_timer.stop()
	velocity.y = -1 * jump_speed
	jumping_up = true
	
	# start jump tween
	var tween = create_tween()
	var h_squash = 0.875
	var v_squash = 1.25
	var v_offset = (1.0 - v_squash) * anim_sprite.sprite_frames.get_frame_texture("jump",0).get_height()
	var squash_in = 0.10
	var squash_out= 0.20
	tween.tween_property(anim_sprite, "scale:x", anim_initial_scale.x * h_squash, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "scale:y", anim_initial_scale.x * v_squash, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "position:y", v_offset, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anim_sprite, "scale:x", anim_initial_scale.x, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "scale:y", anim_initial_scale.y, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "position:y", 0, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	return true

# try to drop from the platform
func _drop_from_platform():
	if is_on_floor():
		collision_mask = collision_mask ^ (1 << 4)
		var timeout = get_tree().create_timer(drop_timeout, true, true)
		timeout.timeout.connect(func(): collision_mask = collision_mask | (1 << 4))

func on_land():
	# start land tween
	var tween = create_tween()
	var h_squash = 1.2
	var v_squash = 0.8
	var v_offset = (1.0 - v_squash) * anim_sprite.sprite_frames.get_frame_texture("jump",0).get_height()
	var squash_in = 0.025
	var squash_out = 0.05
	tween.bind_node(anim_sprite)
	tween.tween_property(anim_sprite, "scale:y", anim_initial_scale.y * v_squash, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "scale:x", anim_initial_scale.x * h_squash, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "position:y", v_offset, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anim_sprite, "scale:y", anim_initial_scale.y, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "scale:x", anim_initial_scale.x, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "position:y", 0, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	#tween.tween_property(anim_sprite, "position:y", anim_initial_scale.y * v_offset, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	#tween.tween_property(anim_sprite, "position:y", 0, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	pass

func _process(_delta: float):
	if abs(velocity.x) > 0:
		anim_sprite.flip_h = (velocity.x < 0)
	
	if not anim_busy:
		_set_movement_anim()
	
	#focus on interactable objects (eg for highlighting them)
	var focus = _get_closest_interactable() #may be null
	if focus != current_focus:
		if current_focus:
			current_focus.end_focus(self)
		if focus:
			focus.start_focus(self)
	current_focus = focus


func _flash_white():
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", Color(2, 2, 2, 1), 0.05)
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1,), 0.10)
	tween.tween_property(anim_sprite, "modulate", Color(2, 2, 2, 1,), 0.15)
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1,), 0.20)

func _get_closest_interactable() -> Interactable:
	var closest: Interactable = null
	var closestDist: float = 0
	for object in ($InteractArea.get_overlapping_areas() + $InteractArea.get_overlapping_bodies()):
		var interactable: Interactable = object as Interactable
		if !interactable: continue
		
		var newDist = global_position.distance_squared_to(object.global_position)
		if closest == null or newDist < closestDist:
			closest = object
			closestDist = global_position.distance_squared_to(closest.global_position)
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

var prev_grounded = false
func _physics_process(delta):
	# handle all character movement in physics
	var move_vec = _read_inputs() 
	
	var curr_grounded = is_on_floor()
	if curr_grounded && !prev_grounded:
		on_land()
	prev_grounded = curr_grounded

	if is_on_floor():
		#ground movement
		velocity.x = move_vec.x * run_speed 
		_jump()
		coyote_timer.start(coyote_time)
	else:
		#air movement
		velocity.x = move_vec.x * air_speed 
		#If you walk off a ledge, you can still jump within a certain window
		if !coyote_timer.is_stopped():
			_jump()
		if gravity_enabled:
			velocity.y += gravity * delta

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
