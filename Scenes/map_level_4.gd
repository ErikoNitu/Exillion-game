extends Node2D

@onready var shop: CanvasLayer = $Shop
@onready var health_container: HBoxContainer = $CanvasLayer/healthContainer
@onready var wizard: CharacterBody2D = $Wizard

func _ready() -> void:
	health_container.setMaxHearts(wizard.maxHealth)
	health_container.updateHearts(wizard.currentHalth)
	wizard.healthChanged.connect(health_container.updateHearts)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			shop.visible = 1;
		if event.keycode == KEY_ESCAPE:
			shop.visible = 0;
