extends CanvasLayer
class_name gui

@onready var collectable_gui = $CollectableGUI
@onready var collectable_label = $CollectableGUI/CollectableLabel

@onready var interact_hold_timer = $Timers/InteractHold

func _ready():
	collectable_gui.modulate = Color(1, 1, 1, 0)

func _process(_delta):
	collectable_label.text = str(RoomManager.obtained_collectables) + " / " + str(RoomManager.total_collectables)
	
	if Input.is_action_just_pressed("interact"):
		interact_hold_timer.start(0.1)

	if Input.is_action_just_released("interact"):
		interact_hold_timer.stop()
		var tween = create_tween()
		tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, 0), 0.2)

func flash_collectables():
	var tween = create_tween()
	tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, 1), 0.2)
	await get_tree().create_timer(2.0).timeout 
	tween = create_tween()
	tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, 0), 0.2)


func _on_interact_hold_timeout():
	#show collectable GUI
	var tween = create_tween()
	tween.tween_property(collectable_gui, "modulate", Color(1, 1, 1, 1), 0.2)
