extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("yo")
		var renpy_game_exe = "C:/Users/Paul/Desktop/GODOT/WINNER/Ren'Py/END_GAME-1.0-pc/END_GAME-1.0-pc/END_GAME.exe"
		OS.shell_open(renpy_game_exe)
		get_tree().reload_current_scene()
