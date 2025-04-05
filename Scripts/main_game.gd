extends Node2D

@onready var health_container: HBoxContainer = $CanvasLayer/healthContainer
@onready var wizard: CharacterBody2D = $Wizard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_container.setMaxHearts(wizard.maxHealth)
	health_container.updateHearts(wizard.currentHalth)
	wizard.healthChanged.connect(health_container.updateHearts)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
