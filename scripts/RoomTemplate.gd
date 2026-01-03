@tool
extends Node2D
class_name RoomTemplate

#Position on global map
#If player exceeds these bounds, room transition
@export var room_bounds: Vector2 =  Vector2(768, 768)
#How player can leave room before transition
@export var exit_leeway = 32

#Time before player gets control when entering room
@export var enter_override_time: float = 0.1

#For display when entering room
@export var room_name: String = ""
@export var creator_name: String = ""

const LEVEL_TILE_STEP: int = 16
const left_bound: int = 0
const upper_bound: int = 0
@export_range(LEVEL_TILE_STEP, 64, LEVEL_TILE_STEP) var width: int = 16
@export_range(LEVEL_TILE_STEP, 64, LEVEL_TILE_STEP) var height: int = 16

@export var save_data: SaveData
@onready var current_scene: PackedScene = load(scene_file_path) as PackedScene

enum Direction {
	Left,
	Right,
	Up,
	Down
}

	
const TILE_SIZE: int = 16 * 3

var boundaries: Array[int]:
	get: return [left_bound, width, upper_bound, height]
	
var world_boundaries: Array[int]:
	get: return [
		left_bound * TILE_SIZE, 
		width * TILE_SIZE,
		upper_bound * TILE_SIZE,
		height * TILE_SIZE
	]

var world_rect: Rect2:
	get: return Rect2(
		boundaries[Direction.Left] * TILE_SIZE,
		boundaries[Direction.Up] * TILE_SIZE,
		(boundaries[Direction.Right] - boundaries[Direction.Left]) * TILE_SIZE,
		(boundaries[Direction.Down] - boundaries[Direction.Up]) * TILE_SIZE,
	)

@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D

#Dictionary that contains anything that needs to be remembered when the room is exited and re-entered
#Eg what enemies have been killed, doors opened etc

var current_checkpoint: Area2D = null 
var current_respawn_point: Vector2 = 0.5 * room_bounds

func create_savedata() -> Dictionary: #store everything to be remembered in savedata dictionary
	var data = {}
	if save_data: 
		data = save_data.create_savedata()
	return data

func receive_savedata(data: Dictionary): #overwrite savedata (called by RoomManager when room loaded)
	if save_data: 
		save_data.receive_savedata(data)

func _create_boundary(pos: Vector2, normal: Vector2) -> Node2D:
	var area = Area2D.new()
	var col_shape = CollisionShape2D.new()
	var shape = WorldBoundaryShape2D.new()
	shape.normal = normal
	col_shape.shape = shape
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.add_child(col_shape)
	add_child(area)
	return area

func _ready():
	if Engine.is_editor_hint():
		return
	
	if camera:
		camera.limit_left = world_boundaries[Direction.Left]
		camera.limit_right = world_boundaries[Direction.Right]
		camera.limit_top = world_boundaries[Direction.Up]
		camera.limit_bottom = world_boundaries[Direction.Down]

	var positions: Array[Vector2] = [
		Vector2(world_boundaries[Direction.Left] - exit_leeway, 0),  # Left
		Vector2(world_boundaries[Direction.Right] + exit_leeway, 0), # Right
		Vector2(0, world_boundaries[Direction.Up] - exit_leeway),    # Up
		Vector2(0, world_boundaries[Direction.Down] + exit_leeway),  # Down
	]
	var normals: Array[Vector2] = [
		Vector2.RIGHT,  # Left
		Vector2.LEFT,   # Right
		Vector2.DOWN,   # Up
		Vector2.UP      # Down
	]
	
	for i in range(Direction.size()):
		var boundary_area = _create_boundary(positions[i], normals[i])
		boundary_area.body_entered.connect(_player_left_screen)
	
	#Load all checkpoint areas
	for checkpoint in get_tree().get_nodes_in_group("checkpoint_areas") as Array[CheckpointArea]:
		checkpoint.entered.connect(_on_checkpoint_entered)
	
	for collectable in get_tree().get_nodes_in_group("collectables") as Array[Collectable]:
		if RoomManager.obtained_current_room_collectable:
			collectable.queue_free()
		else:
			collectable.obtained.connect(_on_collectable_obtained)

	player.death_end.connect(_player_died)
	
	if save_data:
		save_data.load_savedata()
	
	var audio_players = get_tree().get_nodes_in_group("ambient_audio")
	if audio_players.size() > 0:
		#Fade in all ambient audio and start from random position
		var tween = create_tween()
		for audio_player in get_tree().get_nodes_in_group("ambient_audio"):
			audio_player.volume_linear = 0.0
			var length = audio_player.stream.get_length()
			audio_player.play(randf() * length)
			tween.parallel().tween_property(audio_player, "volume_linear", 1.0, 1.0)

func _on_checkpoint_entered(checkpoint: CheckpointArea, _body): 
	current_checkpoint = checkpoint

func _on_collectable_obtained(_collectable: Collectable, _body):
	RoomManager.record_obtained_collectable(scene_file_path)

func _player_died():
	respawn_player(current_respawn_point)

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
	if player.is_safe_position_below():
		current_respawn_point = player.get_safe_position_below()
	else:
		current_respawn_point = player.position #very hacky 
	#disable player control for a short delay
	player.control_enabled = false
	await get_tree().create_timer(enter_override_time).timeout
	player.control_enabled = true

func _on_player_exit(direction: Vector2i): #move to neighbouring room if possible, otherwise respawn player
	var fallback = func():
		respawn_player(current_respawn_point)
		
	if !RoomManager.worldMap.contains(current_scene):
		push_warning("current scene ", current_scene.resource_path, " is not registered in WorldMap")
		return fallback.call() 
		
	var grid_coords = RoomManager.worldMap.level_to_grid(current_scene, player.position)
	var new_map_coords = grid_coords + direction
	if !RoomManager.is_room_at(new_map_coords):
		push_warning("there is no room ", direction, " in world map from ", current_scene.resource_path, " at ", new_map_coords)
		return fallback.call()
		
	RoomManager.transition_to(grid_coords, new_map_coords, direction, player.position, player.velocity)
	var savedata = create_savedata()
	RoomManager.store_savedata(scene_file_path, savedata)
	
	var audio_players = get_tree().get_nodes_in_group("ambient_audio")
	if audio_players.size() > 0:
		var tween = create_tween() #fade out all audio
		for audio_player in audio_players:
			tween.parallel().tween_property(audio_player, "volume_linear", 0.0, 1.0)
	
	_set_child_processing(false) #pause everything
	player.hide()

func _set_child_processing(t_f: bool): #false: pauses everything in room, true: resumes
	for child in get_children():
		child.set_process(t_f)
		child.set_physics_process(t_f)

func respawn_player(pos):
	player.position = pos
	player.respawn()

func _player_in_bounds():
	return player.position.x > 0 and player.position.x < room_bounds.x and player.position.y > 0 and player.position.y < room_bounds.y

func _draw():
	if Engine.is_editor_hint():
		draw_rect(world_rect, Color.DARK_BLUE * Color(1,1,1,0.2))

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()
		return

	if current_checkpoint:
		if current_checkpoint.overlaps_body(player):
			if player.is_safe_position_below():
				current_respawn_point = player.get_safe_position_below()
