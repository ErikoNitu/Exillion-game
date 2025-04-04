extends CharacterBody2D

const SPEED = 230.0
const JUMP_VELOCITY = -400.0
const MOVEMENT_THRESHOLD = 5.0  # Minimum absolute velocity to count as moving

@onready var animated_sprite = $AnimatedSprite2D

var is_attacking = false

# Inputs from Python
var input_left = false
var input_right = false
var input_jump = false
var input_attack = false

# TCP client variables
var client: StreamPeerTCP = StreamPeerTCP.new()
var connected: bool = false
var host: String = "127.0.0.1"
var port: int = 4002
var buffer = ""

# Active time tracking: only count when moving (walking or jumping)
var active_time: float = 0.0

var reset_position = Vector2(0, -100)

func _ready():
	Engine.time_scale = 10.0
	animated_sprite.animation_finished.connect(_on_animation_finished)
	# Connect to Python server
	var err = client.connect_to_host(host, port)
	if err == OK:
		print("Connected to Python server!")
		connected = true
	else:
		print("Failed to connect to Python server! Error code: ", err)
	set_process(true)
	# Use absolute path to get KillZone (adjust this path according to your scene tree)
	var killzone = get_node("/root/Main_Game/KillZone")
	killzone.connect("reset_character", Callable(self, "_reset_character"))

func _physics_process(delta: float) -> void:
	if connected:
		client.poll()
		# Create state to send; note the newline at the end!
		var state = {"is_falling": global_position.y > 800, "nearby_tiles": get_nearby_tiles()}
		var state_json = JSON.stringify(state) + "\n"
		var bytes = state_json.to_utf8_buffer()
		# Send the state
		var put_err = client.put_data(bytes)
		if put_err != OK:
			print("put_data error: ", put_err)
		# Check if there's data available from the server
		var available = client.get_available_bytes()
		if available > 0:
			var received_str = client.get_utf8_string(available)
			buffer += received_str  # accumulate received text into a buffer

			while buffer.find("\n") != -1:
				var newline_index = buffer.find("\n")
				var line = buffer.substr(0, newline_index)
				buffer = buffer.substr(newline_index + 1)

				var json_parser = JSON.new()
				var parse_error = json_parser.parse(line)
				if parse_error == OK:
					var action = json_parser.data
					input_left = action.has("move_left") and action["move_left"]
					input_right = action.has("move_right") and action["move_right"]
					input_jump = action.has("jump") and action["jump"]
					input_attack = action.has("attack") and action["attack"]
				else:
					print("Error parsing JSON:", parse_error, "in line:", line)
		else:
			# If nothing received, clear the inputs
			input_left = false
			input_right = false
			input_jump = false
			input_attack = false

	# --- Apply physics and movement based on external input ---
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if input_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Determine horizontal direction from external inputs
	var direction := 0
	if input_left:
		direction -= 1
	if input_right:
		direction += 1

	# Attack handling
	if input_attack and not is_attacking:
		is_attacking = true
		animated_sprite.play("bam")
	elif not is_attacking:
		if not is_on_floor():
			animated_sprite.play("jump")
		elif direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")

	# Flip sprite based on movement direction
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Move the character
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# --- Active Time Calculation ---
	# We count time only when the character is moving horizontally above a threshold or jumping
	if abs(velocity.x) > MOVEMENT_THRESHOLD or (input_jump and not is_on_floor()):
		active_time += delta
		#print("Active time:", active_time)  # Uncomment to see the active time in the output

func _reset_character():
	print("Player reset triggered!")
	print("Active time:", active_time)
	global_position = reset_position
	# Send reset message to Python
	if connected:
		var reset_state = {"reset": true, "score": active_time}
		var reset_json = JSON.stringify(reset_state) + "\n"
		var reset_bytes = reset_json.to_utf8_buffer()
		client.put_data(reset_bytes)
	# Optionally, reset the active time counter too:
	active_time = 0.0

func _on_animation_finished():
	if is_attacking:
		is_attacking = false

func get_nearby_tiles() -> Array:
	var tilemap = get_node("/root/Main_Game/TileMap")
	var region_size = Vector2(2, 2)  # Number of tiles to sample in each direction from the player
	var local_pos = tilemap.to_local(global_position)
	var player_cell = tilemap.local_to_map(local_pos)
	var nearby_tiles = []

	for y in range(player_cell.y - int(region_size.y), player_cell.y + int(region_size.y) + 1):
		var row = []
		for x in range(player_cell.x - int(region_size.x), player_cell.x + int(region_size.x) + 1):
			# get_cell returns an integer tile index (-1 means no tile)
			var tile_index = tilemap.get_cell_source_id(0, Vector2i(x, y))
			row.append(tile_index)
		nearby_tiles.append(row)

	return nearby_tiles
