extends RoomTemplate


func load_savedata(_data: Dictionary): #apply savedata to objects in room (eg remove enemies that were previously killed)
	pass

func create_savedata() -> Dictionary: #store everything to be remembered in savedata dictionary
	var data = {}
	return data
