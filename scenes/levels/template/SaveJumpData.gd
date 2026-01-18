extends SaveData
class_name SaveJumpData

@onready var player: Player = $"../Player"
var autojump: AutoJump:
	get: return player.find_child("AutoJump")

func load_savedata() -> void: # apply savedata to scene:
	autojump.jump_counter = savedata['jump_counter']
	
func create_savedata() -> Dictionary:
	savedata['jump_counter'] = autojump.jump_counter
	return savedata
