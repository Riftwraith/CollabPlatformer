extends CollisionObject2D
class_name Interactable

signal focus_start 
signal focus_end
signal interacted

func interact(_player: Player): #Called when interact button pressed when focussed
	interacted.emit()

func start_focus(_player: Player): #Called when player moves into range
	focus_start.emit()

func end_focus(_player: Player): #Called when player moves out of range
	focus_end.emit()
