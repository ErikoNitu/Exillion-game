extends PanelContainer

signal SELECTED(index)

@onready var choices_list: VBoxContainer = $MarginContainer/Choices
@onready var button: Button = $MarginContainer/Choices/Button  

var _choices: Array = []  # Directly assign choices for buttons

# Set choices to load scene for specific buttons
func set_choices(value: Array):
	_choices = value
	initButtons()

func get_choices() -> Array:
	return _choices

func _ready() -> void:
	# Ensure the first button is correctly set up
	if choices_list.get_child_count() > 0:
		choices_list.get_child(0).pressed.connect(onChoice.bind(0))

func initButtons():
	print("Initializing buttons...")  # Debug
	# Remove all old buttons
	for child in choices_list.get_children():
		choices_list.remove_child(child)
		child.queue_free()
	
	if button == null:
		print("Error: Button template not found! Make sure a Button exists in the scene.")
		return
	
	# Creating buttons with the correct labels
	for choice_index in range(_choices.size()):
		var new_button: Button
		if choice_index == 0:
			new_button = button  # Reuse first button
		else:
			new_button = button.duplicate(true)  # Duplicate other choices
			choices_list.add_child(new_button)
		
		new_button.text = _choices[choice_index]
		new_button.pressed.connect(onChoice.bind(choice_index))
		print("Created button:", new_button.text)  # Debug

func onChoice(choice_index):
	print("Button pressed:", choice_index)
	visible = false
	SELECTED.emit(choice_index)

	# Load different scenes based on the button pressed
	if choice_index == 1:
		print("Loading scene 1...")
		get_tree().change_scene_to_file("C:/Users/User1/Desktop/joc godot/joc/Scenes/map_level_2.tscn")  # Replace with actual scene path
	elif choice_index == 2:
		print("Loading scene 2...")
		get_tree().change_scene_to_file("C:/Users/User1/Desktop/joc godot/joc/Scenes/map_level_3.tscn")  # Replace with actual scene path

func show_dialog():
	print("Showing dialog")  # Debug
	visible = true
