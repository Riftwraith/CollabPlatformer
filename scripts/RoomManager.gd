# RoomManager.gd
extends Node

@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var GUI = $GUI

var rooms:= {
	Vector2i(0, 0): "res://scenes/levels/example_blockout.tscn",
	Vector2i(0, 1): "res://scenes/levels/level.tscn",
	Vector2i(1, 0): "res://scenes/levels/level2.tscn",
	Vector2i(0, -1): "res://scenes/gyms/slime_gym.tscn",
	Vector2i(-1, 0): "res://scenes/levels/ExampleLevel.tscn",
}

var total_collectables: int = 0
var obtained_collectables: int = 0
var rooms_with_obtained_collectables: Array[String] = []

var room_savedata:= {}

func get_room_at(pos: Vector2i) -> String:
	return rooms.get(pos, "")

func is_room_at(pos: Vector2i) -> bool:
	if rooms.has(pos):
		return true
	return false

func store_savedata(room_path: String, data: Dictionary):
	room_savedata[room_path] = data

func _ready():
	fade_rect.size = get_viewport().size
	fade_rect.hide()
	#calculate total collectables 
	var unique_rooms = []
	for room in rooms:
		if room not in unique_rooms:
			unique_rooms.append(room)
			total_collectables += 1

func record_obtained_collectable(room_path: String):
	if room_path not in rooms_with_obtained_collectables:
		rooms_with_obtained_collectables.append(room_path)
		obtained_collectables += 1
		GUI.flash_collectables()

func transition_to(old_coords:Vector2i, new_coords: Vector2i, direction: Vector2i, player_pos: Vector2, player_vel: Vector2):
	await fade_out(direction)
	get_tree().current_scene.free()
	var room_path = get_room_at(new_coords)
	var new_room = load(room_path).instantiate() as RoomTemplate
	
	if room_savedata.has(room_path): 
		new_room.receive_savedata(room_savedata[room_path])
	
	new_room.map_coords = new_coords
	get_tree().root.add_child(new_room)
	get_tree().current_scene = new_room
	new_room.player_enter(direction, player_pos, player_vel, old_coords)
	await fade_in(direction)

func fade_out(direction: Vector2i):
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.position = fade_rect.size * Vector2(direction)
	print(direction)
	var tween = fade_rect.create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	tween.tween_property(fade_rect, "position", Vector2.ZERO, 0.4)
	await tween.finished

func fade_in(direction: Vector2i):
	var tween = fade_rect.create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.4)
	tween.tween_property(fade_rect, "position", -1 * fade_rect.size * Vector2(direction), 0.4)
	await tween.finished
	fade_rect.visible = false
