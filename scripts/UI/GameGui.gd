extends CanvasLayer
class_name GameGui

@onready var collectable_gui = $CollectableGUI
@onready var collectable_text_rec = $CollectableGUI/KeycapTexture
@onready var collectable_label = $CollectableGUI/CollectableLabel

@onready var title_gui = $RoomTitle
@onready var title_room_name = $RoomTitle/RoomName
@onready var title_creator = $RoomTitle/Creator

@export var collectable_img_col: AtlasTexture
@export var collectable_img_grey: AtlasTexture

@onready var interact_hold_timer = $Timers/InteractHold

var info_tween 


func _ready():
	collectable_gui.modulate = Color(1, 1, 1, 0)
	title_gui.modulate = Color(1, 1, 1, 0)
	collectable_text_rec.texture = collectable_img_grey


func set_titles(room_name: String, creator_name: String):
	title_room_name.text = room_name
	title_creator.text = creator_name

func _process(_delta):
	collectable_label.text = str(RoomManager.obtained_collectables) + " / " + str(RoomManager.total_collectables)
	if RoomManager.obtained_current_room_collectable:
		collectable_text_rec.texture = collectable_img_col
	else:
		collectable_text_rec.texture = collectable_img_grey
	
	if Input.is_action_just_pressed("interact"):
		interact_hold_timer.start(0.1)

	if Input.is_action_just_released("interact"):
		interact_hold_timer.stop()
		_set_info_alpha(0)

func flash(element: Control):
	var tween = create_tween()
	tween.tween_property(element, "modulate", Color(1, 1, 1, 1), 0.2)
	await get_tree().create_timer(2.0).timeout
	if Input.is_action_pressed("interact"):
		return
	tween = create_tween()
	tween.tween_property(element, "modulate", Color(1, 1, 1, 0), 0.2)

func fade_out(direction: Vector2i):
	_set_info_alpha(0)
	var fade_rect = ColorRect.new()
	add_child(fade_rect)
	fade_rect.size = get_viewport().size
	fade_rect.position = fade_rect.size * Vector2(direction)
	
	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(fade_rect, "position", Vector2.ZERO, 0.4)
	await tween.finished
	fade_rect.queue_free()

func fade_in():
	var fade_rect = ColorRect.new()
	add_child(fade_rect)
	fade_rect.size = get_viewport().size
	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.4)
	await tween.finished
	fade_rect.queue_free()

func _set_info_alpha(a: float):
	if info_tween and info_tween.is_running():
		info_tween.kill()
	info_tween = create_tween()
	info_tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, a), 0.2)
	info_tween.parallel().tween_property(title_gui, "modulate", Color(1, 1, 1, a), 0.2)


func _on_interact_hold_timeout():
	#show collectable GUI
	_set_info_alpha(1)
