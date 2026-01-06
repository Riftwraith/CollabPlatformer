# RoomManager.gd
extends Node

const WORLD_TILE_SIZE = 768
@onready var gui: GameGui = $GUI
@onready var worldMap: LevelLoader = $WorldMap

var total_collectables: int = 0
var obtained_collectables: int = 0
var obtained_current_room_collectable: bool = false
var rooms_with_obtained_collectables: Array[String] = []

var room_savedata:= {}

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
	var oldPlayer = room.player
	var oldPlayerVelocity = oldPlayer.velocity
	var oldScene = room.current_scene
	var oldPlayerPos = oldPlayer.position
	var oldGridCoords = worldMap.level_to_grid(oldScene, oldPlayerPos)
	var oldLocalGridCoords = worldMap.get_local_grid(oldGridCoords)
	var oldPlayerLocalGridOffset = oldPlayerPos - Vector2(oldLocalGridCoords * WORLD_TILE_SIZE)
	var nextGridCoords = oldGridCoords + exitDir
	var nextScene = worldMap.get_level_at(nextGridCoords)
	
	if nextScene == null:
		push_warning("player is at ", oldPlayerPos)
		push_warning("there is no room ", exitDir, " in world map from ", oldScene.resource_path, " at ", nextGridCoords)
		room.respawn_player()
		return
	
	var nextLocalGridCoords = worldMap.get_local_grid(nextGridCoords)
	var newPlayerPos = Vector2(nextLocalGridCoords - exitDir) * WORLD_TILE_SIZE + oldPlayerLocalGridOffset
	
	# pause the level
	room._set_child_processing(false) #pause everything
	oldPlayer.hide()
	
	# fade out
	await fade_out(exitDir)
	
	# unload level
	room.cleanup()
	get_tree().current_scene.free()
	
	# load level
	var newRoom = nextScene.instantiate() as RoomTemplate
	get_tree().root.add_child(newRoom)
	get_tree().current_scene = newRoom
	
	# set level params
	var newRoomPath = nextScene.resource_path
	obtained_current_room_collectable = newRoomPath in rooms_with_obtained_collectables
	if room_savedata.has(newRoomPath):
		newRoom.receive_savedata(room_savedata[newRoomPath])
	var newPlayer = newRoom.player
	newPlayer.position = newPlayerPos
	match exitDir:
		Vector2i.UP: newPlayer.velocity = Vector2.UP * newPlayer.jump_speed
		Vector2i.DOWN: 
			newPlayer.position += Vector2.UP * 96
			newPlayer.velocity = oldPlayerVelocity
		_: newPlayer.velocity = Vector2(exitDir) * newPlayer.run_speed
	fade_in()
	

func fade_out(direction: Vector2i):
	var fade_rect = ColorRect.new()
	gui.add_child(fade_rect)
	fade_rect.size = get_viewport().size
	fade_rect.position = fade_rect.size * Vector2(direction)
	
	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(fade_rect, "position", Vector2.ZERO, 0.4)
	await tween.finished
	fade_rect.queue_free()

func fade_in():
	var fade_rect = ColorRect.new()
	gui.add_child(fade_rect)
	fade_rect.size = get_viewport().size
	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.4)
	await tween.finished
	fade_rect.queue_free()
