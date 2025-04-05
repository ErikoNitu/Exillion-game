extends Area2D

@export var speed: float = 200.0
var direction: Vector2 = Vector2.RIGHT

func _process(delta: float) -> void:
	position += direction * speed * delta
