# RoomManager.gd
extends Node

@onready var GUI = $GUI
@onready var worldMap: LevelLoader = $WorldMap

var total_collectables: int = 0
var obtained_collectables: int = 0
var obtained_current_room_collectable: bool = false
var rooms_with_obtained_collectables: Array[String] = []

var room_savedata:= {}

func level_to_grid(scene: PackedScene, level_coord: Vector2) -> Vector2i:
	return worldMap.level_to_grid(scene, level_coord)

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
	var current_room = get_tree().current_scene
	GUI.set_titles(current_room.room_name, current_room.creator_name)
	GUI.flash(GUI.title_gui)
	

func record_obtained_collectable(room_path: String):
	obtained_current_room_collectable = true
	if room_path not in rooms_with_obtained_collectables:
		rooms_with_obtained_collectables.append(room_path)
		obtained_collectables += 1
		GUI.flash(GUI.collectable_gui)

func transition_to(old_coords:Vector2i, new_coords: Vector2i, direction: Vector2i, player_pos: Vector2, player_vel: Vector2):
	await fade_out(direction)
	get_tree().current_scene.free()
	var room_path = worldMap.get_level_at(new_coords).resource_path
	print("room path: ", room_path)
	
	if room_path in rooms_with_obtained_collectables:
		obtained_current_room_collectable = true
	else:
		obtained_current_room_collectable = false

	var new_room = load(room_path).instantiate() as RoomTemplate
	
	if room_savedata.has(room_path): 
		new_room.receive_savedata(room_savedata[room_path])
	
	get_tree().root.add_child(new_room)
	get_tree().current_scene = new_room
	new_room.player_enter(direction, player_pos, player_vel, old_coords)
	
	GUI.set_titles(new_room.room_name, new_room.creator_name)
	GUI.flash(GUI.title_gui)

	await fade_in(direction)


func fade_out(direction: Vector2i):
	var fade_rect = ColorRect.new()
	GUI.add_child(fade_rect)
	fade_rect.size = get_viewport().size
	fade_rect.modulate.a = 0.0
	fade_rect.position = fade_rect.size * Vector2(direction)
	print(direction)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	tween.tween_property(fade_rect, "position", Vector2.ZERO, 0.4)
	await tween.finished
	fade_rect.queue_free()

func fade_in(direction: Vector2i):
	var fade_rect = ColorRect.new()
	GUI.add_child(fade_rect)
	fade_rect.size = get_viewport().size
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.4)
	tween.tween_property(fade_rect, "position", -1 * fade_rect.size * Vector2(direction), 0.4)
	await tween.finished
	fade_rect.queue_free()
