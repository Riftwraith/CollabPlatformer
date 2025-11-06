extends Node2D
class_name Level

@export var room_coords: Vector2i = Vector2i(0, 0)

#If player exceeds these bounds, room transition
@export var room_bounds: Vector2 =  Vector2(768, 768)
@export var exit_leeway = 32

@onready var player = $Player
@onready var test_rigid_body = $RigidBody2D

var saved_player_position:= 0.5 * Vector2(768, 768)

var save_data:= {}

func _load_save_data():
	if save_data == {}:
		return
	test_rigid_body.position = save_data["test_body_pos"]
	test_rigid_body.rotation = save_data["test_body_rot"]

func _create_save_data():
	save_data["test_body_pos"] = test_rigid_body.position
	save_data["test_body_rot"] = test_rigid_body.rotation

func _ready():
	$RoomBoundaries/Left.position = Vector2(-1 * exit_leeway, 0)
	$RoomBoundaries/Right.position = room_bounds + Vector2(exit_leeway, 0)
	$RoomBoundaries/Up.position = Vector2(0, -1 * exit_leeway)
	$RoomBoundaries/Down.position = room_bounds + Vector2(0, exit_leeway)
	
	_load_save_data()



func _player_left_screen(_body):
	if player.position.x < 0:
		_on_player_exit(Vector2i.LEFT)
	if player.position.x > room_bounds.x:
		_on_player_exit(Vector2i.RIGHT)
	if player.position.y < 0:
		_on_player_exit(Vector2i.UP)
	if player.position.y > room_bounds.y:
		_on_player_exit(Vector2i.DOWN)

func player_enter(direction: Vector2i, exit_player_pos: Vector2, exit_player_vel: Vector2, _enter_from_coords: Vector2i):
	#direction is player movement direction
	#exit_player_pos is coords of player 
	#exit_player_vel is velocity of player
	#_enter_from_coords is the coords of the room the player is coming from (unused)
	match direction:
		Vector2i.LEFT:
			player.position = Vector2(room_bounds.x, exit_player_pos.y)
			player.velocity = Vector2(min(exit_player_vel.x, -1 * player.run_speed), exit_player_vel.y)
		Vector2i.RIGHT:
			player.position = Vector2(0, exit_player_pos.y)
			player.velocity = Vector2(max(exit_player_vel.x, player.run_speed), exit_player_vel.y)
		Vector2i.UP:
			player.position = Vector2(exit_player_pos.x, room_bounds.y) 
			player.velocity = Vector2(exit_player_vel.x, min(exit_player_vel.y, -1 * player.jump_speed))
		Vector2i.DOWN:
			player.position = Vector2(exit_player_pos.x, 0) 
			player.velocity = exit_player_vel
	player.control_enabled = false
	await get_tree().create_timer(0.5).timeout
	player.control_enabled = true


func _on_player_exit(direction: Vector2i):
	var new_room_coords = room_coords + direction 
	if RoomManager.is_room_at(new_room_coords):
		RoomManager.transition_to(room_coords, new_room_coords, direction, player.position, player.velocity)
		print("heading_to " + str(new_room_coords))
		_create_save_data()
		RoomManager.save_data(scene_file_path, save_data)
		player.queue_free()
	else:
		#reset p;ayer position
		player.position = saved_player_position

func _process(_delta):
	#check if player on ground & within bounds: if so, make save state
	if is_instance_valid(player):
		if player.position.x > 0 and player.position.x < room_bounds.x and player.position.y > 0 and player.position.y < room_bounds.y:
			if player.is_on_floor():
				saved_player_position = player.position
