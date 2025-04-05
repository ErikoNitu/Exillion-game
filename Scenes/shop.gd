extends CanvasLayer

@onready var shop: CanvasLayer = $"." 

@onready var currItem = 0
@onready var fireball = 0
@onready var time = 0
@onready var wand = 0

func _on_close_pressed() -> void:
	shop.visible = false  # Use false instead of 0

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
	if currItem == 0:
		fireball = 1;
		print(Global.items[currItem])
		print(fireball)
	if currItem == 1:
		wand = 1;
		print(Global.items[currItem])
	if currItem == 2:
		time = 1;
		print(Global.items[currItem])


func _on_animated_sprite_2d_ready() -> void:
	switchItem(0)
