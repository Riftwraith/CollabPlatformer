@abstract
class_name Player
extends CharacterBody2D

var current_focus: Interactable = null # current interactable object
var prev_grounded = false
var control_enabled: bool = false

@export var impact_speed_threshold = 500 # impacts at higher speed than this made sound
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var front_ray: RayCast2D = $FloorRayCasts/FrontRay
@onready var back_ray: RayCast2D = $FloorRayCasts/BackRay
@onready var interact_area: Area2D = $InteractArea
@onready var gravity_controller: GravityController = $GravityController
@onready var player_height: float = 0.5 * collision_shape.shape.height + collision_shape.position.y

signal death_begin
signal death_end
signal spawn_begin
signal spawn_end
signal on_jump
signal on_land
signal on_collide
#
@abstract func init_logic() -> void
@abstract func input_logic() -> void
@abstract func movement_logic(delta: float) -> void
@abstract func animation_logic(delta: float) -> void
@abstract func respawn_logic() -> void
@abstract func death_logic(death_velocity: Vector2) -> void

#region Public functions 
func play_respawn_feedback() -> void: # play respawn animation and temporarily disable control
	velocity = Vector2.ZERO
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE # disable collision

	gravity_controller.enabled = true
	control_enabled = false
	spawn_begin.emit()
	await respawn_logic()
	
	control_enabled = true
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

#region Godot Intrinsics
func _ready() -> void:
	init_logic()
	control_enabled = true

func _process(delta: float) -> void:
	_read_inputs()
	animation_logic(delta)

	var focus: Interactable = _get_closest_interactable()
	if focus != current_focus:
		if current_focus:
			current_focus.end_focus(self)
		if focus:
			focus.start_focus(self)
	current_focus = focus

func _physics_process(delta: float) -> void:
	var curr_grounded = is_on_floor()
	if curr_grounded && !prev_grounded:
		on_land.emit()
	movement_logic(delta)

	gravity_controller.apply_gravity(delta)
	move_and_slide()
	
	_handle_collisions(delta)
	prev_grounded = curr_grounded
	
func _read_inputs():
	if !control_enabled:
		return

	input_logic()
	if Input.is_action_just_pressed("interact"):
		if current_focus != null:
			current_focus.interact(self)

func _handle_collisions(delta: float) -> void: # currently only does pushing of Rigidbodies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if not collision: return
		var collider = collision.get_collider()
		
		var collision_pos = collision.get_position()
		var collision_speed = ((collision.get_travel() + collision.get_remainder()) / delta).dot(-1 * collision.get_normal())
		if collision_speed > impact_speed_threshold:
			on_collide.emit()
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

func _die(death_velocity: Vector2) -> void:
	disable_mode = CollisionObject2D.DISABLE_MODE_MAKE_STATIC
	gravity_controller.enabled = false
	control_enabled = false
	death_begin.emit()
	
	await death_logic(death_velocity)
	
	death_end.emit()

#endregion

#region
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
	
#endregion

#region Signals
func _on_hurtbox_enter(_collider: Node2D):
	_die(Vector2.ZERO)

func _on_hurtbox_enter_area2D(_collider: Area2D):
	_die(Vector2.ZERO)

#endregion
