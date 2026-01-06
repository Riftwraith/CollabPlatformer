extends SaveData

#Saves whether the door is open or closed
@export var wooden_door: WoodenDoor


func create_savedata() -> Dictionary:
	savedata["door_status"] = wooden_door.status
	return savedata

func load_savedata():
	if savedata == {}:
		return
	wooden_door.status = savedata["door_status"]
	wooden_door.update_status()
