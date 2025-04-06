extends Control


func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map_level_1.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()



func _on_story_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/story_1.tscn")
