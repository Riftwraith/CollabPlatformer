extends CollisionObject2D
class_name Interactable

signal focus_start ##Called when player moves into range
signal focus_end ##Called when player moves out of range
signal interacted ##Emitted when interact button pressed when focussed

func interact(_player: Player): 
	interacted.emit()

func start_focus(_player: Player): 
	focus_start.emit()

func end_focus(_player: Player): 
	focus_end.emit()
