@tool
extends Sprite2D
class_name LevelProxy

@export var scene: PackedScene
var viewport: SubViewport

static func create_proxy(theScene: PackedScene, parent: Node):
	var retval = LevelProxy.new()
	parent.add_child(retval)
	retval.owner = parent
	retval.scene = theScene
	retval.centered = false
	
	print("initializing ", theScene.resource_path)
	retval.name = theScene.resource_path.trim_prefix("res://scenes/levels/").trim_suffix(".tscn")
	retval._initialize_screenshot()
	return retval

func _initialize_screenshot():
	var scene_tree: RoomTemplate = scene.instantiate()
	viewport = SubViewport.new()
	viewport.add_child(scene_tree)
	add_child(viewport)
	#scene_tree.owner = owner
	#viewport.owner = owner
	
	var world_rect = scene_tree.world_rect
	var camera = Camera2D.new()
	viewport.size = world_rect.size
	camera.limit_left = world_rect.position.x
	camera.limit_right = world_rect.end.x
	camera.limit_top = world_rect.position.y
	camera.limit_bottom = world_rect.end.y
	scene_tree.add_child(camera)
	await RenderingServer.frame_post_draw

	#const render_tile_size = 256
	#viewport.size_2d_override = (
		#Vector2i(scene_tree.width, scene_tree.height) 
		#/ scene_tree.LEVEL_TILE_SIZE 
		#* render_tile_size)
	#print(viewport.size_2d_override)
	#viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	texture = ImageTexture.create_from_image(viewport.get_texture().get_image())	
	viewport.queue_free()
