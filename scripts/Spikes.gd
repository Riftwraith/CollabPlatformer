extends Node2D

@export var knockback_speed = 200

func _on_area_2d_body_entered(body):
	if body is Player:
		if body.dying: return
		var knockback_vec = body.global_position - global_position
		knockback_vec = knockback_vec.normalized() * knockback_speed
		body.die(knockback_vec)
