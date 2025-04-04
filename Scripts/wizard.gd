extends CharacterBody2D

const SPEED = 230.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite = $AnimatedSprite2D

var is_attacking = false

# Inputs received from the Python server:
var input_left = false
var input_right = false
var input_jump = false
var input_attack = false

# TCP client variables
var client: StreamPeerTCP = StreamPeerTCP.new()
var connected: bool = false
var host: String = "127.0.0.1"
var port: int = 4242

func _ready():
	print("we're readu to go!")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	# Connect to Python server
	print("we're readu to go!")
	var err = client.connect_to_host(host, port)
	if err == OK:
		print("Connected to Python server!")
		connected = true
	else:
		print("Failed to connect to Python server!")
	set_process(true)

func _physics_process(delta: float) -> void:
	print("here?")
	# --- Communicate with Python server ---
	if connected:
		# Build a simple state; here we send whether the player is "falling"
		var state = {"is_falling": global_position.y > 800}
		var state_json = JSON.stringify(state) + "\n"
		var bytes = state_json.to_utf8()
		# Send the state
		client.put_data(bytes)
		client.flush()
		
		# Check if there's an incoming message
		if client.get_available_bytes() > 0:
			var received_str = client.get_utf8_string(client.get_available_bytes())
			var json = JSON.new()
			var result = json.parse(received_str)
			if result.error == OK:
				var action = result.result
				# Update the control flags based on the received JSON
				input_left = action.has("move_left") and action["move_left"]
				input_right = action.has("move_right") and action["move_right"]
				input_jump = action.has("jump") and action["jump"]
				input_attack = action.has("attack") and action["attack"]
			else:
				print("Error parsing action JSON")
		else:
			# If no data is received, set all actions to false
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

	# Flip sprite based on movement
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

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
