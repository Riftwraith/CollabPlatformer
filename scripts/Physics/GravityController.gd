extends Node
class_name GravityController

@export var gravity_scale: float = 1.0
@export var enabled: bool = true

var gravity: float:
	get: return physics_cfg.gravity
var effective_gravity: float:
	get: return physics_cfg.gravity * gravity_scale

@onready var affected_controller: CharacterBody2D = get_node("..")
@onready var physics_cfg: PhysicsConfig = load("res://scripts/Physics/PhysicsConfig.tres")

func apply_gravity(delta: float):
	if !enabled:
		return
		
	if affected_controller.is_on_floor():
		return

	affected_controller.velocity.y += gravity_scale * gravity * delta
