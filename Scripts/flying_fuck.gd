extends Node2D

const SPEED: float = 300.0
@export var patrol_distance: float = 200.0

@onready var start_position: Vector2 = position
@onready var current_health: int = 2
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

@export var shoot_cooldown: float = 1.5
var projectile_scene: PackedScene = preload("res://Scenes/fireball.tscn")

var direction: int = 1
var is_dying: bool = false
var can_shoot: bool = true

func _ready() -> void:
	start_position = position
	detection_area.area_entered.connect(_on_detection_area_body_entered)
	animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dying:
		return

	animated_sprite.play("run")
	position.x += direction * SPEED * delta

	# Check patrol distance
	var distance_from_start = position.x - start_position.x
	if abs(distance_from_start) >= patrol_distance:
		direction *= -1
		animated_sprite.flip_h = direction < 0

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
		var dir = (player.global_position - global_position).normalized()
		projectile.direction = dir
