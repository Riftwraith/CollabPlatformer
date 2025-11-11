extends Path2D

@onready var follower = $PathFollow2D

@export var speed: float = 300
@export var direction: int = 1
@export var lock_rotation = true
var t: float = 0.0
@export var freq = 1

func _ready():
	#Reparent all children to the follower
	follower.loop = false
	for child in get_children():
		if child == follower: continue
		remove_child(child)
		follower.add_child(child)


func _physics_process(delta):
	t += delta
	if t > TAU: t = t - TAU 
	follower.progress_ratio = 0.5 * (-1 * cos(freq * t) + 1)
	
	if lock_rotation:
		follower.rotation = 0
