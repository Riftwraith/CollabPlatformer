extends Node2D
class_name RoomTemplate

#Position on global map
@export var map_coords: Vector2i = Vector2i(0, 0)
#If player exceeds these bounds, room transition
@export var room_bounds: Vector2 =  Vector2(768, 768)
#How player can leave room before transition
@export var exit_leeway = 32
#Time before player gets control when entering room
@export var enter_override_time: float = 0.3


@onready var player = $Player

var last_safe_player_position:= 0.5 * map_coords

#Dictionary that contains anything that needs to be remembered when the room is exited and re-entered
#Eg what enemies have been killed, doors opened etc
var savedata:= {}
var savedata_updated := false

func _load_savedata(): #apply savedata to objects in room (eg remove enemies that were previously killed)
	pass

func _create_savedata(): #store everything to be remembered in savedata dictionary
	pass

func receive_savedata(data: Dictionary): #overwrite savedata (called by RoomManager when room loaded)
	savedata = data
	savedata_updated = true

func _ready():
	#Set boundary areas to correct positions
	$RoomBoundaries/Left.position = Vector2(-1 * exit_leeway, 0)
	$RoomBoundaries/Right.position = room_bounds + Vector2(exit_leeway, 0)
	$RoomBoundaries/Up.position = Vector2(0, -1 * exit_leeway)
	$RoomBoundaries/Down.position = room_bounds + Vector2(0, exit_leeway)
	
	if savedata_updated:
		_load_savedata()

func _player_left_screen(_body): #receives signal from boundary areas when the player enters them
	if player.position.x < 0:
		_on_player_exit(Vector2i.LEFT)
	if player.position.x > room_bounds.x:
		_on_player_exit(Vector2i.RIGHT)
	if player.position.y < 0:
		_on_player_exit(Vector2i.UP)
	if player.position.y > room_bounds.y:
		_on_player_exit(Vector2i.DOWN)

func player_enter( #called when player enters the room from a different room
	direction: Vector2i,  #player movement direction
	exit_player_pos: Vector2, #position of player in previous room 
	exit_player_vel: Vector2, #velocity of player in previous room
	_enter_from_coords: Vector2i #map_coords of previous room (unused)
	): 
	match direction: #put the player at the right place depending on the direction used to enter the room
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
	#disable player control for a short delay
	player.control_enabled = false
	await get_tree().create_timer(enter_override_time).timeout
	player.control_enabled = true


func _on_player_exit(direction: Vector2i): #move to neighbouring room if possible, otherwise respawn player
	var new_map_coords = map_coords + direction 
	if RoomManager.is_room_at(new_map_coords):
		RoomManager.transition_to(map_coords, new_map_coords, direction, player.position, player.velocity)
		_create_savedata()
		RoomManager.store_savedata(scene_file_path, savedata)
		_set_child_processing(false) #pause everything
		player.hide()
	else:
		#reset player position
		_respawn_player(last_safe_player_position)

func _set_child_processing(t_f: bool): #false: pauses everything in room, true: resumes
	for child in get_children():
		child.set_process(t_f)
		child.set_physics_process(t_f)

func _respawn_player(pos):
	player.position = pos
	player.respawn()

func _player_in_bounds():
	if player.position.x > 0 and player.position.x < room_bounds.x and player.position.y > 0 and player.position.y < room_bounds.y:
		return true
	return false

func _process(_delta):
	#check if player on ground & within bounds: if so, save position
	if _player_in_bounds() and player.is_on_safe_ground():
		last_safe_player_position = player.position
