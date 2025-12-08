extends PointLight2D

# get the texture from the TextureRect
@onready var vp = $SubViewport
@onready var texture_rect = $TextureRect

func _ready():
	RenderingServer.frame_post_draw.connect(_after_first_render, Object.CONNECT_ONE_SHOT)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	texture_rect.hide()
	offset = 0.5 * vp.size
	position = Vector2(0.001, 0.001)

func _after_first_render():
	# At this moment the SubViewport has rendered ONCE already.
	var img = vp.get_texture().get_image()
	var light_tex = ImageTexture.create_from_image(img)
	print(light_tex)
	texture = light_tex
