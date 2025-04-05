extends Node2D

const SPEED: float = 50.0

@onready var current_health: int = 3
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var detection_area: Area2D = $DetectionArea

@export var shoot_cooldown: float = 1.5
var projectile_scene: PackedScene = preload("res://Scenes/fireball.tscn")

var direction: int = -1
var is_dying: bool = false
var can_shoot: bool = true

var client: StreamPeerTCP = StreamPeerTCP.new()
var connected: bool = false
var host: String = "127.0.0.1"
var port: int = 4004

func _ready() -> void:
	Engine.time_scale = 2.0
	var err = client.connect_to_host(host, port)
	if err == OK:
		print("Connected to Python server!")
		connected = true
	else:
		print("Failed to connect to Python server! Error code: ", err)
	detection_area.area_entered.connect(_on_detection_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_dying:
		animated_sprite.play("run")

		if ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = true
		elif ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = false

		position.x += direction * SPEED * delta

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_attack":
		current_health -= 1
		if current_health <= 0 and not is_dying:
			die()

func die() -> void:
	is_dying = true
	direction = 0
	animated_sprite.play("death")

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_dying:
		queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if not is_dying and can_shoot and body.is_in_group("player"):
		shoot_projectile()
		can_shoot = false
		await get_tree().create_timer(shoot_cooldown).timeout
		can_shoot = true

func shoot_projectile() -> void:
	if projectile_scene == null:
		return
		
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Calculate the base (current) direction from enemy to player
		var base_dir = Vector2(0, -1)# (player.global_position - global_position).normalized()
		var correct_dir = (player.global_position - global_position).normalized()

		# Prepare a dictionary with the info you want to send to Python
		var state = {
			"projectile_direction": [correct_dir.x, correct_dir.y],
			"player_position": [player.global_position.x, player.global_position.y],
			"enemy_position": [global_position.x, global_position.y]
		}
		var state_json = JSON.stringify(state) + "\n"
		var bytes = state_json.to_utf8_buffer()
		
		# Send the state to Python
		client.poll()
		var put_err = client.put_data(bytes)
		if put_err != OK:
			print("put_data error: ", put_err)
		
		# Wait briefly to allow the server to respond
		# (In a real-time game you might run this in a coroutine or check repeatedly)
		var available = client.get_available_bytes()
		if available > 0:
			var received_str = client.get_utf8_string(available)
			# We assume the response ends with a newline
			var newline_index = received_str.find("\n")
			if newline_index != -1:
				var line = received_str.substr(0, newline_index)
				var json_parser = JSON.new()
				var parse_error = json_parser.parse(line)
				if parse_error == OK:
					var response = json_parser.data
					if response.has("projectile_direction"):
						var pred = response["projectile_direction"]
						var predicted_dir = Vector2(pred[0], pred[1])
						# Use the predicted direction from Python for the projectile
						projectile.direction = predicted_dir.normalized()
						print("Updated projectile direction from Python:", projectile.direction)
					else:
						# Fallback: use the base direction
						projectile.direction = base_dir
						print("No projectile_direction in response; using base direction")
				else:
					print("Error parsing response JSON:", parse_error)
					projectile.direction = base_dir
			else:
				# No complete message yet; fallback to base direction
				projectile.direction = base_dir
		else:
			# If no response is available, use the base direction
			projectile.direction = base_dir

func generate_random_direction() -> Vector2:
	# Generate a random angle in radians between 0 and 2π
	var angle = randf_range(0, 2 * PI)
	
	# Convert the angle to a unit vector (direction vector)
	var direction = Vector2(cos(angle), sin(angle))
	
	return direction
	
func generate_random_position_around(center: Vector2, radius: float = 100.0) -> Vector2:
	# Generate a random angle in radians
	var angle = randf_range(0, 2 * PI)
	
	# Generate a random distance with uniform distribution within the circle
	var distance = sqrt(randf()) * radius
	
	# Calculate offset from the center
	var offset = Vector2(cos(angle), sin(angle)) * distance
	
	# Return the new random position
	return center + offset
