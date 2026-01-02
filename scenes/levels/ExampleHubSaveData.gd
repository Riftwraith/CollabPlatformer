extends SaveData

#Saves whether the door is open or closed

func create_savedata() -> Dictionary:
	savedata["door_status"] = $"../Objects/WoodenDoor".status
	return savedata

func load_savedata():
	if savedata == {}:
		return
	$"../Objects/WoodenDoor".status = savedata["door_status"]
	$"../Objects/WoodenDoor".update_status()
