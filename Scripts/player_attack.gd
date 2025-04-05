extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):  # Only affects the player
		print("die !")
