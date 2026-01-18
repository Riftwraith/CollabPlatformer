extends SaveData

#Saves whether the door is open or closed
@export var wooden_door: WoodenDoor
@export var conveyor: Conveyor


func create_savedata() -> Dictionary:
	savedata["door_status"] = wooden_door.status
	savedata["conveyor_active"] = conveyor.active
	print("creating savedata")
	print(savedata["conveyor_active"])
	return savedata

func load_savedata():
	if savedata == {}:
		return
	wooden_door.status = savedata["door_status"]
	conveyor.active = savedata["conveyor_active"]
	print("loading savedata")
	print(savedata["conveyor_active"])
	wooden_door.update_status()
