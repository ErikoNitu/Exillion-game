extends Node2D

const SPEED: float = 0.0

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

var connected: bool = false
var host: String = "127.0.0.1"
var port: int = 4004

@onready var shoot_timer: Timer = $Timer


func _ready() -> void:
	Engine.time_scale = 2.0
	detection_area.area_entered.connect(_on_detection_area_body_entered)
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_ShootTimer_timeout)

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
	if area.name == "Player_attack" or area.name == "Void":
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

#func _on_detection_area_body_entered(body: Node2D) -> void:
	#if not is_dying and can_shoot and body.is_in_group("player"):
		#shoot_projectile()
		#can_shoot = false
		#await get_tree().create_timer(shoot_cooldown).timeout
		#can_shoot = true
		
var is_player_inside: bool = false

func _on_detection_area_body_entered(body: Node2D) -> void:
	if not is_dying and body.is_in_group("player"):
		# Mark that the player is inside the area.
		is_player_inside = true
		# Immediately shoot once.
		shoot_projectile()
		# Start the timer to shoot repeatedly.
		$Timer.start(shoot_cooldown)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Mark that the player left the area.
		is_player_inside = false
		# Stop the timer so shooting stops.
		$Timer.stop()

func _on_ShootTimer_timeout() -> void:
	# If the player is still in the area and the enemy is not dying, shoot another projectile.
	print("timerdone")
	if is_player_inside and not is_dying:
		print("shooting")
		shoot_projectile()



func shoot_projectile() -> void:
	var client: StreamPeerTCP = StreamPeerTCP.new()
	var err = client.connect_to_host(host, port)
	if err == OK:
		print("Connected to Python server!")
		connected = true
	else:
		print("Failed to connect to Python server! Error code: ", err)

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


func _on_hurtbox_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
