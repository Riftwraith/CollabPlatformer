# RoomManager.gd
extends Node

const WORLD_TILE_SIZE = 768
@onready var gui: GameGui = $GUI
@onready var worldMap: LevelLoader = $WorldMap

var total_collectables: int = 0
var obtained_collectables: int = 0
var obtained_current_room_collectable: bool = false
var rooms_with_obtained_collectables: Array[String] = []

var room_savedata := {}

func is_room_at(pos: Vector2i) -> bool:
	return worldMap.get_level_at(pos) != null

func store_savedata(room_path: String, data: Dictionary):
	room_savedata[room_path] = data

func _ready():
	#calculate total collectables 
	var unique_rooms: Array[PackedScene] = []
	for room in worldMap.levels:
		if room not in unique_rooms:
			unique_rooms.append(room)
			total_collectables += 1

func record_obtained_collectable(room_path: String):
	obtained_current_room_collectable = true
	if room_path not in rooms_with_obtained_collectables:
		rooms_with_obtained_collectables.append(room_path)
		obtained_collectables += 1
		gui.flash(gui.collectable_gui)

func enqueue_level_change(exitDir: Vector2i, room: RoomTemplate):
	get_tree().process_frame.connect(_level_change.bind(exitDir, room))
	return

func _level_change(exitDir: Vector2i, room: RoomTemplate):
	# disconnect on call
	get_tree().process_frame.disconnect(_level_change)
	
	if !worldMap.contains(room.current_scene):
		push_warning("current scene ", room.current_scene.resource_path, " is not registered in WorldMap")
		room.respawn_player()
		return
	
	# retrieve params for next level
	var old_player = room.player
	var old_player_velocity = old_player.velocity
	var old_scene = room.current_scene
	var old_playerPos = old_player.position
	var old_grid_coords = worldMap.level_to_grid(old_scene, old_playerPos)
	var old_local_grid_coords = worldMap.get_local_grid(old_grid_coords)
	var old_player_local_grid_offset = old_playerPos - Vector2(old_local_grid_coords * WORLD_TILE_SIZE)
	var next_grid_coords = old_grid_coords + exitDir
	var next_scene = worldMap.get_level_at(next_grid_coords)
	
	if next_scene == null:
		push_warning("player is at ", old_playerPos)
		push_warning("there is no room ", exitDir, " in world map from ", old_scene.resource_path, " at ", next_grid_coords)
		room.respawn_player()
		return
	
	var nextLocalGridCoords = worldMap.get_local_grid(next_grid_coords)
	var newPlayerPos = Vector2(nextLocalGridCoords - exitDir) * WORLD_TILE_SIZE + old_player_local_grid_offset
	
	# pause the level
	room._set_child_processing(false) # pause everything
	old_player.hide()
	
	# fade out
	await gui.fade_out(exitDir)
	
	# unload level
	room.cleanup()
	get_tree().current_scene.free()
	
	# load level
	var newRoom = next_scene.instantiate() as RoomTemplate
	get_tree().root.add_child(newRoom)
	get_tree().current_scene = newRoom
	
	# set level params
	var newRoomPath = next_scene.resource_path
	obtained_current_room_collectable = newRoomPath in rooms_with_obtained_collectables
	if room_savedata.has(newRoomPath):
		newRoom.receive_savedata(room_savedata[newRoomPath])
	var newPlayer = newRoom.player
	newPlayer.position = newPlayerPos
	match exitDir:
		Vector2i.UP: newPlayer.velocity = Vector2.UP * newPlayer.jump_speed
		Vector2i.DOWN:
			newPlayer.position += Vector2.UP * 96
			newPlayer.velocity = old_player_velocity
		_: newPlayer.velocity = Vector2(exitDir) * newPlayer.run_speed
	gui.fade_in()
