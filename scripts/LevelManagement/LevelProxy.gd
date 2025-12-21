@tool
extends Node2D
class_name LevelProxy

func create_proxy(scene: PackedScene):
	print("initializing ", scene.resource_path)
	name = scene.resource_path.trim_prefix("res://scenes/levels/").trim_suffix(".tscn")
	pass
