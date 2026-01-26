extends Player
class_name DefaultPlayer

# DefaultPlayer is an example of a Player implementation
#
# The implementation of a Player is responsible for:
# - Handling movement logic
# - Handling feedback logic (animations, tweens, etc.)
#
# The core Player loop is handled in Player.gd
# It handles interactibles and gravity, which we expect all implementations to support
# Override the functions in Player Logic Overrides to insert your logic into the core Player
#   eg. Double jump, wave dash logic would go here

const one_way_collision_mask = 1 << 4
@export var run_speed: float = 150
@export var air_speed: float = 150
@export var jump_height: int = 98 # in pixels
@export var coyote_time: float = 0.1 # s time you can jump after walking off ledge
@export var jump_queue_time: float = 0.1 # s time you can jump before landing
@export var drop_timeout: float = 0.25 # s how long to disable collision when dropping through platforms
@export var jump_peak_threshold = 50 # when velocity.y is greater than this, have passed jump peak

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_initial_scale: Vector2 = anim_sprite.scale
@onready var jump_queue_timer: Timer = $Timers/JumpQueueTimer
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_speed = sqrt(2 * jump_height * gravity_controller.gravity)
@onready var sounds = {
	"respawn": $Sounds/Respawn,
	"jump": $Sounds/Jump,
	"impact": $Sounds/Hurt,
	"die": $Sounds/Die,
}

var anim_busy: bool = false # lock animation (eg for respawning)
var jumping_up: bool = false # flag if releasing "jump" should reduce velocity.y
var move_vec: Vector2

#region Player Logic Overrides
func init_logic():
	anim_sprite.animation = "idle"
	anim_sprite.play()

	on_land.connect(func():
		_squash_and_stretch(
			1.2, # hsquash
			0.8, # vsquash
			0.025, # squash_in
			0.05, # squash_out
		)
	)
	on_collide.connect(func():
		sounds["impact"].play())

func input_logic():
	if !control_enabled:
		return

	move_vec = Vector2.ZERO
		
	if Input.is_action_pressed("left"):
		move_vec += Vector2.LEFT
	if Input.is_action_pressed("right"):
		move_vec += Vector2.RIGHT
		
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("down"):
			_drop_from_platform()
		else:
			_queue_jump()

	# shorter jump when released halfway
	if Input.is_action_just_released("jump"):
		if jumping_up and velocity.y <= 0:
			velocity.y = 0.5 * velocity.y # limit jump height
			jumping_up = false


func movement_logic(_delta):
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

func animation_logic(_delta: float):
	# update the animation state based on the current state of the player
	if anim_busy:
		return

	if abs(velocity.x) > 0:
		anim_sprite.flip_h = (velocity.x < 0)
	
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

# this is the respawn animation
func respawn_logic() -> void:
	anim_busy = true
	anim_sprite.animation = "respawn"
	anim_sprite.play()
	_flash_white(2)
	sounds["respawn"].play()
	await anim_sprite.animation_finished
	anim_busy = false

# this is the death animation
func death_logic(death_velocity: Vector2) -> void:
	_flash_white(1)
	velocity = death_velocity
	anim_busy = true
	sounds["die"].play()
	anim_sprite.play("die")
	await anim_sprite.animation_finished
	anim_busy = false

#endregion

#region Private functions

func _queue_jump() -> void:
	#can press jump key when just about to land 
	jump_queue_timer.start(jump_queue_time)

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
	if is_on_floor():
		collision_mask ^= one_way_collision_mask
		var timeout = get_tree().create_timer(drop_timeout, true, true)
		timeout.timeout.connect(func(): collision_mask |= one_way_collision_mask)

#endregion

#region Feedback Animations

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
