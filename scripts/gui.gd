extends CanvasLayer
class_name gui

@onready var collectable_gui = $CollectableGUI
@onready var collectable_text_rec = $CollectableGUI/KeycapTexture
@onready var collectable_label = $CollectableGUI/CollectableLabel

@onready var title_gui = $RoomTitle
@onready var title_room_name = $RoomTitle/RoomName
@onready var title_creator = $RoomTitle/Creator

@export var collectable_img_col: AtlasTexture
@export var collectable_img_grey: AtlasTexture

@onready var interact_hold_timer = $Timers/InteractHold

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
		var tween = create_tween()
		tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.parallel().tween_property(title_gui, "modulate", Color(1, 1, 1, 0), 0.2)

func flash(element: Control):
	var tween = create_tween()
	tween.tween_property(element, "modulate", Color(1, 1, 1, 1), 0.2)
	await get_tree().create_timer(2.0).timeout
	if Input.is_action_pressed("interact"):
		return
	tween = create_tween()
	tween.tween_property(element, "modulate", Color(1, 1, 1, 0), 0.2)

func _on_interact_hold_timeout():
	#show collectable GUI
	var tween = create_tween()
	tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.parallel().tween_property(title_gui, "modulate", Color(1, 1, 1, 1), 0.2)
