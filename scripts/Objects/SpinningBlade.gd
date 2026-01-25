extends Node2D

@onready var particle_node = $Particles
@onready var anim_sprite = $AnimatedSprite2D

@export var particle_rot_speed = 1


func _ready():
	anim_sprite.play()
	for child in particle_node.get_children() as Array[CPUParticles2D]:
		child.emitting = true

func _process(delta):
	particle_node.rotation += particle_rot_speed * delta
