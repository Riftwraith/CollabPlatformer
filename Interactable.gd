extends CollisionObject2D
class_name Interactable

func interact(player: Player):
	print(str(player.name) + " interacted with " + str(self.name))

func start_focus(player: Player):
	print(str(self.name) + " ready to interact")

func end_focus(player: Player):
	print(str(self.name) + " no longer ready to interact") 
