extends CanvasLayer

@onready var shop: CanvasLayer = $"." 

@onready var currItem = 0
@onready var fireball = 0
@onready var time = 0
@onready var wand = 0
@onready var wizard: CharacterBody2D = $"../Wizard"
@onready var map_level_1: Node2D = $".."
@onready var map_level_2: Node2D = $".."
@onready var map_level_4: Node2D = $".."

func _on_close_pressed() -> void:
	shop.visible = false  # Use false instead of 0
	map_level_1.unpause_enemies()
	map_level_2.unpause_enemies()
	map_level_4.unpause_enemies()
func switchItem(select: int):
	# Ensure select is within valid range
	if select < 0 or select >= Global.items.size():
		return  

	currItem = select
	var item = Global.items[currItem]  # Get the dictionary once to avoid redundant lookups

	get_node("Control/AnimatedSprite2D").play(Global.items[currItem]["Name"])
	get_node("Control/Name").text = item["Name"]
	get_node("Control/Description").text = item["Description"] + "\nCost: " + str(item["Cost"])
	
	

func _on_next_pressed() -> void:
	switchItem(currItem + 1)

func _on_prev_pressed() -> void:
	switchItem(currItem - 1)

func _on_buy_pressed() -> void:
	if currItem == 0 and wizard.currentHalth > 4:
		Global.fireball = 1;
		print(Global.items[currItem])
		wizard.currentHalth -= 4
		wizard.healthChanged.emit(wizard.currentHalth)
	if currItem == 1 and wizard.currentHalth > 2:
		Global.wand = 1;
		print(Global.items[currItem])
		wizard.currentHalth -= 2
		wizard.healthChanged.emit(wizard.currentHalth)
	if currItem == 2 and wizard.currentHalth > 3:
		Global.time = 1;
		print(Global.items[currItem])
		wizard.currentHalth -= 3
		wizard.healthChanged.emit(wizard.currentHalth)
		

func _on_animated_sprite_2d_ready() -> void:
	switchItem(0)
