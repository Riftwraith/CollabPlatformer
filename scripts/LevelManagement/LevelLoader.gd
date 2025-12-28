@tool
class_name LevelLoader
extends Node

#### Let us define the following coordinate spaces:
####    LEVEL COORDS: Vector2  refer to a position in the loaded level
####    WORLD COORDS: Vector2  refer to a position in the world map's level
####    GRID  COORDS: Vector2i refer to a position in the level grid.

@export var worldDims: Vector2i = Vector2i(8, 8)
@export var levels: Array[PackedScene] = []
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) var level_cache: Dictionary[String, NodePath] = {}
@onready var _proxy_parent: Node2D = $Proxies
var _world: Array[LevelProxy]

var proxies: Array[LevelProxy]:
	get: 
		return Array(_proxy_parent.get_children(), TYPE_OBJECT, "Node2D", LevelProxy)

@export_tool_button("Reset Cache") var reset = reset_cache
func reset_cache() -> void:
	for child in _proxy_parent.get_children():
		print("freeing ", child.name)
		child.free()
	level_cache = {}
	_create_level_proxies()
	
func get_level_proxy_at(worldCoord: Vector2i) -> LevelProxy:
	# bounds check
	if (worldCoord.x < 0 || worldCoord.x >= worldDims.x ||
		worldCoord.y < 0 || worldCoord.y >= worldDims.y):
		return null
	return _world[_grid_to_flat_index(worldCoord)]

func get_target_level(curr_scene: PackedScene, position_in_level: Vector2, transition_direction: Vector2i) -> PackedScene:
	var grid_pos = _level_to_grid(curr_scene, position_in_level)
	var level_proxy = get_level_proxy_at(grid_pos + transition_direction)
	if level_proxy:
		assert(level_proxy != curr_scene)
		return level_proxy.scene
	else:
		return null

func _level_to_grid(scene: PackedScene, player_pos_in_level: Vector2) -> Vector2i:
	const LEVEL_TILE_SIZE = 768 # scale 3 * 16 cell per grid scale * 16px per cell  
	var proxy_path = level_cache[scene.resource_path]
	var proxy = get_node(proxy_path) as LevelProxy
	var player_world_map_pos = proxy.position + player_pos_in_level # TEMP: LIKELY TO BREAK IF WORLD IS SCALED
	return player_world_map_pos / LEVEL_TILE_SIZE

# local to WorldMap level
func _world_to_grid(from: Vector2) -> Vector2i:
	const TILE_SIZE = 768 # scale 3 * 16 cell per grid scale * 16px per cell  
	return Vector2i(from / TILE_SIZE)

func _grid_to_flat_index(from: Vector2i) -> int:
	return from.y * worldDims.x + from.x

@export_tool_button("Test WorldArray") var worldArrayTest = _computeWorldArray
func _computeWorldArray() -> Array[LevelProxy]:
	var world_flat_size = worldDims.x * worldDims.y
	var arr = Array([], TYPE_OBJECT, "Node2D", LevelProxy)
	arr.resize(world_flat_size)
	for proxy in proxies:
		var grid_pos = _world_to_grid(proxy.position)
		var grid_size = proxy.grid_size
		#print("proxy: ", proxy, " pos: ", grid_pos, " sz:" , grid_size)
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				var idx = _grid_to_flat_index(grid_pos + Vector2i(x, y))
				arr[idx] = proxy
				print(idx, ": ", proxy)
				
	if Engine.is_editor_hint():
		for y in range(worldDims.y):
			var printStr = ""
			for x in range(worldDims.x):
				var grid_pos = Vector2i(x, y)
				var idx = _grid_to_flat_index(grid_pos)
				printStr += str(grid_pos) + ": "
				var proxy: LevelProxy = arr[idx]
				if proxy != null:
					printStr += proxy.name + "  "
				else:
					printStr += "<empt>   "
			print(printStr)
		#print(arr)
	return arr

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
			level_proxy = LevelProxy.create_proxy(level, _proxy_parent)
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
	else:
		for proxy in proxies:
			proxy.texture = null
		_world = _computeWorldArray()
		
