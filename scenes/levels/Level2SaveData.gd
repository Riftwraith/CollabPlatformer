extends SaveData

func create_savedata() -> Dictionary:
	savedata["ball_position"] = $"../RigidBody2D".position
	savedata["ball_rotation"] = $"../RigidBody2D".rotation
	return savedata

func load_savedata():
	if savedata == {}:
		return
	$"../RigidBody2D".position = savedata["ball_position"]
	$"../RigidBody2D".rotation = savedata["ball_rotation"]
