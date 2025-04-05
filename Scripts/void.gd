extends Area2D

@export var speed: float = 400.0
var direction: int = 1

func _ready() -> void:
	$Timer.start()
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.get_parent().is_in_group("enemy"):
		print("pac")
	if not body.is_in_group("player"):
		queue_free()
