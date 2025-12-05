extends Area2D
class_name  CheckpointArea

signal entered

func _on_body_entered(body):
	entered.emit(self, body)
