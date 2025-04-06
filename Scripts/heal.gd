extends Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func collect():
	animation_player.play("pickup")
	#queue_free()
