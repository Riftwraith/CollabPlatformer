@tool
class_name LevelLoader
extends Node

@export var levels: Array[PackedScene] = []
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) var level_cache: Dictionary[String, NodePath] = {}

@export_tool_button("Reset Cache") var reset = reset_cache
func reset_cache() -> void:
	for child in get_children():
		print("freeing ", child.name)
		child.free()
	level_cache = {}
	_create_level_proxies()
	print("done")

func _create_level_proxies() -> void:
	var level_names: Array[String] = []
	for level in levels:
		if level == null:
			push_warning("null level in level list, skipping")
			continue

		var level_id = level.resource_path
		var find_level = level_cache.get(level_id)
		var level_proxy: LevelProxy
		if find_level != null:
			level_proxy = get_node(find_level)
		else:
			level_proxy = LevelProxy.create_proxy(level, self)
			find_level = get_path_to(level_proxy)
			level_cache.set(level_id, find_level)
		level_names.append(level_proxy.name)
	
	for child in get_children():
		if level_names.find(child.name) == null:
			child.queue_free()

func _ready() -> void:
	print(levels.size())
	if Engine.is_editor_hint():
		_create_level_proxies()
		EditorInterface.get_inspector().property_edited.connect(func(_p): 
			reset_cache())
	print("ready")
			
		#var scene = level.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		#var search = scene as RoomTemplate
		#if search == null:
			#push_warning("WorldMap level ", level.resource_path, " root does not have script RoomTemplate")
			#continue
		#print(level.resource_path, " has boundaries ", search.boundaries)
		
