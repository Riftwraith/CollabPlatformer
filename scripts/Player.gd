extends CharacterBody2D
class_name Player


@export var run_speed: float = 150
@export var air_speed: float = 150
@export var jump_height: int = 98 # in pixels
@export var coyote_time: float = 0.1 # s time you can jump after walking off ledge
@export var jump_queue_time: float = 0.1 # s time you can jump before landing
@export var drop_timeout: float = 0.25 # s how long to disable collision when dropping through platforms
@export var jump_peak_threshold = 50 # when velocity.y is greater than this, have passed jump peak
@export var impact_speed_threhold = 500 # impacts at higher speed than this made sound

@onready var hurtbox: Area2D = $Hurtbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interact_area: Area2D = $InteractArea
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_initial_scale: Vector2 = anim_sprite.scale
@onready var jump_queue_timer: Timer = $Timers/JumpQueueTimer
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var front_ray: RayCast2D = $FloorRayCasts/FrontRay
@onready var back_ray: RayCast2D = $FloorRayCasts/BackRay
@onready var gravity_controller: GravityController = $GravityController

@onready var sounds = {
	"respawn": $Sounds/Respawn,
	"jump": $Sounds/Jump,
	"impact": $Sounds/Hurt,
	"die": $Sounds/Die,
}

var control_enabled: bool = true # accepts player input or not
var anim_busy: bool = false # lock animation (eg for respawning)

var jump_speed: float
var player_height: float # distance from origin to player's feet
var jumping_up: bool = false # flag if releasing "jump" should reduce velocity.y
var prev_grounded = false

var current_focus: Interactable = null # current interactable object

signal death_begin
signal death_end
signal spawn_begin
signal spawn_end
signal on_jump

#region Public functions 
func play_respawn_feedback() -> void: # play respawn animation and temporarily disable control
	velocity = Vector2.ZERO
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE # disable collision
	gravity_controller.enabled = true
	control_enabled = false
	anim_busy = true
	anim_sprite.animation = "respawn"
	anim_sprite.play()
	_flash_white(2)
	sounds["respawn"].play()
	spawn_begin.emit()
	
	await anim_sprite.animation_finished
	
	control_enabled = true
	anim_busy = false
	spawn_end.emit()

func is_safe_position_below() -> bool: # is there a flat area to stand on below
	if not front_ray.is_colliding() or not back_ray.is_colliding():
		return false
	var front_y = front_ray.get_collision_point().y
	var back_y = back_ray.get_collision_point().y
	if back_y == front_y:
		return true
	return false

func get_safe_position_below() -> Vector2:
	if not is_safe_position_below():
		return Vector2.ZERO
	return Vector2(position.x, front_ray.get_collision_point().y - player_height)
#endregion


#region Godot Functions
func _ready(): # called when first loaded in
	#calculate jump speed so that player has correct jump height
	jump_speed = sqrt(2 * jump_height * gravity_controller.gravity)
	player_height = 0.5 * collision_shape.shape.height + collision_shape.position.y
	anim_sprite.animation = "idle"
	anim_sprite.play()

func _process(_delta: float): # called every frame
	if abs(velocity.x) > 0:
		anim_sprite.flip_h = (velocity.x < 0)
	
	if not anim_busy:
		_set_movement_anim()
	
	#focus on interactable objects (eg for highlighting them)
	var focus: Interactable = _get_closest_interactable() # may be null
	if focus != current_focus:
		if current_focus:
			current_focus.end_focus(self)
		if focus:
			focus.start_focus(self)
	current_focus = focus

func _physics_process(delta): # called every physics frame
	# handle all character movement in physics
	var move_vec = _read_inputs()
	
	var curr_grounded = is_on_floor()
	if curr_grounded && !prev_grounded: # just landed
		# start land tween	
		_squash_and_stretch(
			1.2, # hsquash
			0.8, # vsquash
			0.025, # squash_in
			0.05, # squash_out
		)
	prev_grounded = curr_grounded

	if is_on_floor():
		#ground movement
		if control_enabled:
			velocity.x = move_vec.x * run_speed
		_handle_jump()
		coyote_timer.start(coyote_time)
	else:
		#air movement
		if control_enabled:
			velocity.x = move_vec.x * air_speed
		#If you walk off a ledge, you can still jump within a certain window
		if !coyote_timer.is_stopped():
			_handle_jump()
			
		if jumping_up && abs(velocity.y) < jump_peak_threshold: # reduce gravity if holding jump
			gravity_controller.gravity_scale = 0.5
		else:
			gravity_controller.gravity_scale = 1.0
	
	gravity_controller.apply_gravity(delta)
	move_and_slide()
	
	_handle_collisions(delta)
			
#endregion

#region Private functions
#region Game Logic
func _read_inputs() -> Vector2: # handles input and returns a 2d direction vector
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
			velocity.y = 0.5 * velocity.y # limit jump height
			jumping_up = false
	if Input.is_action_just_pressed("interact"):
		var interactable = _get_closest_interactable()
		if interactable != null:
			interactable.interact(self)
	return move_vec
	
func _handle_collisions(delta: float) -> void: # currently only does pushing of Rigidbodies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if not collision: return
		var collider = collision.get_collider()
		
		var collision_pos = collision.get_position()
		var collision_speed = ((collision.get_travel() + collision.get_remainder()) / delta).dot(-1 * collision.get_normal())
		if collision_speed > impact_speed_threhold:
			await get_tree().process_frame
			sounds["impact"].play()
		var tilemap = collider as TileMapLayer
		if tilemap:
			var tile_coord = tilemap.local_to_map(tilemap.to_local(collision_pos))
			var _tile_data: TileData = tilemap.get_cell_tile_data(tile_coord)
			#does nothing
			pass
		
		if collider is RigidBody2D: # pushable
			var coll_speed = (collision.get_travel() + collision.get_remainder()).length() / delta
			var push_dir = -1 * collision.get_normal()
			var push_strength = 0.01 * coll_speed
			collider.apply_impulse(push_dir * push_strength, collision.get_position() - collider.global_position)

func _queue_jump() -> void:
	#can press jump key when just about to land 
	jump_queue_timer.start(jump_queue_time)

enum AnchorDirection {
	Top,
	Bottom,
}

func _handle_jump() -> bool:
	# returns true if a jump was successfully done
	# false if the jump failed (eg. jump cooldown not exceeded)
	if jump_queue_timer.is_stopped():
		return false
	
	jump_queue_timer.stop()
	coyote_timer.stop()
	velocity.y = -1 * jump_speed
	jumping_up = true
	
	# start jump tween
	_squash_and_stretch(
		0.875, # hsquash
		1.25, # vsquash
		0.10, # squash_in
		0.20, # squash_out
	)
	sounds["jump"].pitch_scale = randf_range(0.95, 1.05)
	sounds["jump"].play()
	
	# emit jump signal
	on_jump.emit()
	return true

func _drop_from_platform() -> void: # try to drop from a platform
	#does this by temporarily disabling collisions with all platforms
	const one_way_collision_mask = 1 << 4
	if is_on_floor():
		collision_mask ^= one_way_collision_mask
		var timeout = get_tree().create_timer(drop_timeout, true, true)
		timeout.timeout.connect(func(): collision_mask |= one_way_collision_mask)

	
func _get_closest_interactable() -> Interactable: # returns closest object in InteractArea
	var closest: Interactable = null
	var closest_dist: float = 0
	for object in (interact_area.get_overlapping_areas() + interact_area.get_overlapping_bodies()):
		var interactable: Interactable = object as Interactable
		if !interactable: continue
		
		var new_dist = global_position.distance_squared_to(object.global_position)
		if closest == null or new_dist < closest_dist:
			closest = object
			closest_dist = global_position.distance_squared_to(closest.global_position)
	return closest
	
func _die(knockback_velocity: Vector2) -> void: # plays death animation and disables control
	disable_mode = CollisionObject2D.DISABLE_MODE_MAKE_STATIC
	gravity_controller.enabled = false
	
	anim_sprite.play("die")
	_flash_white(1)
	velocity = knockback_velocity
	anim_busy = true
	control_enabled = false
	sounds["die"].play()
	death_begin.emit()
	
	await anim_sprite.animation_finished
	
	death_end.emit()

#endregion

#region Feedback Animations

func _set_movement_anim() -> void: # changes sprite animation based on velocity
	anim_sprite.play()
	
	if not is_on_floor():
		#fall/jump
		if velocity.y < 0:
			anim_sprite.animation = "jump"
		if velocity.y > 0:
			anim_sprite.animation = "fall"
	else:
		#ground anims"
		if abs(velocity.x) > 0:
			anim_sprite.animation = "run"
		else:
			anim_sprite.animation = "idle"
			
func _flash_white(n: int) -> void:
	#sprite flashes white n times
	var tween = create_tween()
	for i in range(n):
		tween.tween_property(anim_sprite, "modulate", Color(2, 2, 2, 1), 0.10 * n + 0.05)
		tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1, ), 0.10 * n + 0.10)


# squash scales are in local space
# squash durations are in seconds
func _squash_and_stretch(horizontal_squash: float, vertical_squash: float, squash_in_dur: float, squash_out_dur: float) -> Tween:
	var tween = create_tween()
	var h_squash = horizontal_squash
	var v_squash = vertical_squash
	var v_offset = (1.0 - v_squash) * anim_sprite.sprite_frames.get_frame_texture("jump", 0).get_height()
	var squash_in = squash_in_dur
	var squash_out = squash_out_dur
	tween.tween_property(anim_sprite, "scale:x", anim_initial_scale.x * h_squash, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "scale:y", anim_initial_scale.x * v_squash, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "position:y", v_offset, squash_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anim_sprite, "scale:x", anim_initial_scale.x, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "scale:y", anim_initial_scale.y, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(anim_sprite, "position:y", 0, squash_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	return tween
	
#endregion

#endregion

#region Signals
func _on_hurtbox_enter(_collider: Node2D):
	_die(Vector2.ZERO)

func _on_hurtbox_enter_area2D(_collider: Area2D):
	_die(Vector2.ZERO)

#endregion
