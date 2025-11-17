extends CollisionObject2D
class_name Interactable

signal focus_start 
signal focus_end
signal interacted

func interact(_player: Player):
	interacted.emit()

func start_focus(_player: Player):
	focus_start.emit()

func end_focus(_player: Player):
	focus_end.emit()
