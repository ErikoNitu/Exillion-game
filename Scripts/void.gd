extends Area2D

@export var speed: float = 400.0
var direction: int = 1

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
