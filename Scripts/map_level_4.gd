extends Node2D

@onready var shop: CanvasLayer = $Shop
@onready var health_container: HBoxContainer = $CanvasLayer/healthContainer
@onready var wizard: CharacterBody2D = $Wizard

func _ready() -> void:
	health_container.setMaxHearts(wizard.maxHealth)
	health_container.updateHearts(wizard.currentHalth)
	wizard.healthChanged.connect(health_container.updateHearts)

func pause_enemies():
	for enemy in get_children():
		if enemy is Node2D:  # Check if the child is an enemy (can be changed depending on your enemy node type)
			enemy.set_process_mode(Node.PROCESS_MODE_DISABLED)  # Stop the processing of this enemy

# Unpause all enemies
func unpause_enemies():
	for enemy in get_children():
		if enemy is Node2D:  # Ensure it's an enemy node
			enemy.set_process_mode(Node.PROCESS_MODE_INHERIT)  # Unpause and let it inherit the pause state
	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_E and not get_tree().paused:
			shop.visible = true
			pause_enemies()
		elif event.keycode == KEY_ESCAPE:
			shop.visible = false
			get_tree().paused = false
			unpause_enemies()
		elif event.keycode == KEY_2:
			get_tree().change_scene_to_file("res://Scenes/map_level_2.tscn")
		elif event.keycode == KEY_3:
			get_tree().change_scene_to_file("res://Scenes/map_level_4.tscn")
		elif event.keycode == KEY_1:
			get_tree().change_scene_to_file("res://Scenes/map_level_1.tscn")
		elif event.keycode == KEY_TAB:
			get_tree().change_scene_to_file("res://Scenes/menu.tscn")
