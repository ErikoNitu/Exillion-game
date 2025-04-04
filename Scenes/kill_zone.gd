# KillZone.gd
extends Area2D

signal reset_character

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	#print("KillZone touched by:", body)
	if body.is_in_group("player"):
		#print("KillZone: emitting reset_character")
		emit_signal("reset_character")
