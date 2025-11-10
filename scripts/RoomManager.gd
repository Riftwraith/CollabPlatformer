# RoomManager.gd
extends Node

@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

var rooms:= {
	Vector2i(0, 0): "res://scenes/levels/Level.tscn",
	Vector2i(0, 1): "res://scenes/levels/level2.tscn",
	Vector2i(1, 0): "res://scenes/levels/level2.tscn",
	Vector2i(0, -1): "res://scenes/levels/level2.tscn",
	Vector2i(-1, 0): "res://scenes/levels/level2.tscn",
}

func get_room_at(pos: Vector2i) -> String:
	return rooms.get(pos, "")

func is_room_at(pos: Vector2i) -> bool:
	if rooms.has(pos):
		return true
	return false

var room_savedata:= {}

func store_savedata(room_path: String, data: Dictionary):
	room_savedata[room_path] = data

func _ready():
	fade_rect.size = get_viewport().size
	fade_rect.hide()

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
