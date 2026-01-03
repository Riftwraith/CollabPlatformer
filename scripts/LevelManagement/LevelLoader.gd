@tool
class_name LevelLoader
extends Node2D

#### Let us define the following coordinate spaces:
####    LEVEL COORDS: Vector2  refer to a position in the loaded level
####    WORLD COORDS: Vector2  refer to a position in the world map's level
####    GRID  COORDS: Vector2i refer to a position in the grid of levels in world map.

const WORLD_TILE_SIZE = 768
@export var skipScreenshotInEditor: bool = false
@export var worldDims: Vector2i = Vector2i(8, 8)
@export var levels: Array[PackedScene] = []
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) var level_cache: Dictionary[String, NodePath] = {}
@onready var _proxy_parent: Node2D = $Proxies
var _world: Array[LevelProxy]

var proxies: Array[LevelProxy]:
	get: 
		return Array(_proxy_parent.get_children(), TYPE_OBJECT, "Node2D", LevelProxy)

	
@export_tool_button("Update Proxies") var refresh = _refresh_data
func _refresh_data() -> void:
	var deleteQueue: Array[LevelProxy] = []
	for proxy in proxies:
		if !(proxy.scene in levels):
			deleteQueue.push_back(proxy)
	for deleteMe in deleteQueue:
		print("deleting ", deleteMe)
		level_cache.erase(deleteMe.scene.resource_path)
		deleteMe.free()
	_create_level_proxies()

@export_tool_button("Snap Proxies") var snap = func():
	for proxy in proxies:
		var pos = proxy.global_position
		pos /= WORLD_TILE_SIZE
		pos.x = roundf(pos.x)
		pos.y = roundf(pos.y)
		pos *= WORLD_TILE_SIZE
		proxy.global_position = pos
	
@export_tool_button("Reset Proxies") var reset = reset_cache
func reset_cache() -> void:
	for child in _proxy_parent.get_children():
		print("freeing ", child.name)
		child.free()
	level_cache = {}
	_refresh_data()


func _get_level_proxy_at(worldCoord: Vector2i) -> LevelProxy:
	# bounds check
	if (worldCoord.x < 0 || worldCoord.x >= worldDims.x ||
		worldCoord.y < 0 || worldCoord.y >= worldDims.y):
		return null
	return _world[_grid_to_flat_index(worldCoord)]
	
func get_level_at(worldCoord: Vector2i) -> PackedScene:
	var level_proxy = _get_level_proxy_at(worldCoord)
	if level_proxy:
		return level_proxy.scene
	else:
		return null

func get_target_level(curr_scene: PackedScene, position_in_level: Vector2, transition_direction: Vector2i) -> PackedScene:
	var grid_pos = level_to_grid(curr_scene, position_in_level)
	var level_proxy = _get_level_proxy_at(grid_pos + transition_direction)
	if level_proxy:
		assert(level_proxy != curr_scene)
		return level_proxy.scene
	else:
		return null

func contains(scene: PackedScene) -> bool:
	return scene.resource_path in level_cache 

func level_to_grid(scene: PackedScene, player_pos_in_level: Vector2) -> Vector2i:
	const LEVEL_TILE_SIZE = 768 # scale 3 * 16 cell per grid scale * 16px per cell  
	
	var proxy_path = level_cache[scene.resource_path]
	var proxy = get_node(proxy_path) as LevelProxy
	
	player_pos_in_level.x = clamp(player_pos_in_level.x, 0, proxy.grid_size.x * LEVEL_TILE_SIZE - 1)
	player_pos_in_level.y = clamp(player_pos_in_level.y, 0, proxy.grid_size.y * LEVEL_TILE_SIZE - 1)
	var player_world_map_pos = proxy.position + player_pos_in_level # TEMP: LIKELY TO BREAK IF WORLD IS SCALED
	return player_world_map_pos / LEVEL_TILE_SIZE

func _world_to_grid(from: Vector2) -> Vector2i:
	const TILE_SIZE = 768 # scale 3 * 16 cell per grid scale * 16px per cell  
	return Vector2i(from / TILE_SIZE)

func _grid_to_flat_index(from: Vector2i) -> int:
	return from.y * worldDims.x + from.x

#@export_tool_button("Test WorldArray") var worldArrayTest = _compute_world_array
func _compute_world_array() -> Array[LevelProxy]:
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
		
		print("level id ", level_id)
		var level_proxy: LevelProxy
		if find_level != null:
			level_proxy = get_node(find_level)
			level_proxy.refresh_data()
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
	if Engine.is_editor_hint() && !skipScreenshotInEditor:
		print("loading levels ", skipScreenshotInEditor)
		_create_level_proxies()
		EditorInterface.get_inspector().property_edited.connect(func(_p): 
			_refresh_data())
	else:
		# this code comes from when a Proxy is a Sprite2D
		# however, storing the cached sprite texture anyway will load it even
		# in-game
		#
		# so we make the proxies create a Sprite2D child, and skip creation
		# when we're not in the editor. there are probably smarter ways to do
		# this, but there's no need to overengineer the tooling this much
		# 
		# either way, only henry and ivan should be touching this code.
		# 
		#for proxy in proxies:
			#proxy.texture = null
		_world = _compute_world_array()
		

func _draw():
	if Engine.is_editor_hint():
		for x in range(0, worldDims.x + 1):
			draw_line(Vector2(x, 0) * WORLD_TILE_SIZE, Vector2(x, worldDims.y) * WORLD_TILE_SIZE, Color.AQUA)
		for y in range(0, worldDims.y + 1):
			draw_line(Vector2(0, y) * WORLD_TILE_SIZE, Vector2(worldDims.x, y) * WORLD_TILE_SIZE, Color.AQUA)
		
		# border
		const border_color = Color.RED
		const border_width = 10
		draw_line(Vector2(0, 0) * WORLD_TILE_SIZE, Vector2(0, worldDims.y) * WORLD_TILE_SIZE, border_color, border_width)
		draw_line(Vector2(worldDims.x, 0) * WORLD_TILE_SIZE, Vector2(worldDims.x, worldDims.y) * WORLD_TILE_SIZE, border_color, border_width)
		draw_line(Vector2(0, 0) * WORLD_TILE_SIZE, Vector2(worldDims.x, 0) * WORLD_TILE_SIZE, border_color, border_width)
		draw_line(Vector2(0, worldDims.y) * WORLD_TILE_SIZE, Vector2(worldDims.x, worldDims.y) * WORLD_TILE_SIZE, border_color, border_width)
		
func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()
		return
