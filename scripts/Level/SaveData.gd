@abstract
class_name SaveData
extends Node

var savedata = {}

@abstract func load_savedata() -> void # apply savedata to scene

@abstract func create_savedata() -> Dictionary # store everything to be remembered in savedata dictionary

func receive_savedata(data: Dictionary): # apply savedata to objects in room (eg remove enemies that were previously killed)
	savedata = data
