@tool
extends Node2D
class_name LevelProxy

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) var scene: PackedScene
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) var grid_size: Vector2i 
var sprite: Sprite2D

@export_tool_button("Edit Level") var edit_level = func():
	EditorInterface.open_scene_from_path(scene.resource_path)

static func create_proxy(theScene: PackedScene, parent: Node):
	var retval = LevelProxy.new()
	parent.add_child(retval)
	retval.owner = parent.owner
	retval.scene = theScene
	
	print("initializing ", theScene.resource_path)
	retval.name = theScene.resource_path.trim_prefix("res://scenes/levels/").trim_suffix(".tscn")
	retval._instantiate_scene()
	return retval

@export_tool_button("Refresh") var refresh = refresh_data
func refresh_data() -> void:
	_instantiate_scene()

#func _ready() -> void:
	#if !sprite:
		#_instantiate_scene()

func _instantiate_scene():
	print("taking screenshot of ", scene.resource_path)
	var scene_tree: RoomTemplate = scene.instantiate()
	grid_size = Vector2i(scene_tree.width, scene_tree.height) / 16
	_take_screenshot(scene_tree)

func _take_screenshot(scene_tree: RoomTemplate):
	var viewport = SubViewport.new()
	viewport.add_child(scene_tree)
	add_child(viewport)
	
	var world_rect = scene_tree.world_rect
	var camera = Camera2D.new()
	viewport.size = world_rect.size
	camera.limit_left = world_rect.position.x
	camera.limit_right = world_rect.end.x
	camera.limit_top = world_rect.position.y
	camera.limit_bottom = world_rect.end.y
	scene_tree.add_child(camera)

	# consider resizing the textures
	#const render_tile_size = 256
	#viewport.size_2d_override = (
		#Vector2i(scene_tree.width, scene_tree.height) 
		#/ scene_tree.LEVEL_TILE_SIZE 
		#* render_tile_size)
	#print(viewport.size_2d_override)
	#viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	sprite.texture = ImageTexture.create_from_image(viewport.get_texture().get_image())	
	viewport.queue_free()
