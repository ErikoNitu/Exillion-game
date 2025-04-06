extends CharacterBody2D

signal healthChanged

@onready var SPEED = 230.0
const JUMP_VELOCITY = -500.0

@onready var my_timer: Timer = $MyTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var energy_ball_scene: PackedScene = preload("res://Scenes/void.tscn")

@export var maxHealth = 10
@onready var currentHalth: int = 1

var is_attacking = false
var is_firing = false
var stop_time = false

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var direction := Input.get_axis("move_left", "move_right")
	# Attack
	if Input.is_action_just_pressed("attack_melee") and not is_attacking and currentHalth > 1 and Global.wand == 1:
		is_attacking = true
		currentHalth -= 1
		healthChanged.emit(currentHalth)
		if animated_sprite.flip_h == false:
			animation_player.play("attack_melee")
		else:
			animation_player.play("attack_melee_right")
		animated_sprite.play("bam")
	if Input.is_action_just_pressed("fire") and currentHalth > 2 and Global.fireball == 1:
		is_firing = true
		currentHalth -= 2
		healthChanged.emit(currentHalth)
		animated_sprite.play("fire")
		shoot_projectile()
	if Input.is_action_just_pressed("time_stop") and currentHalth > 3 and Global.time == 1:
		Engine.time_scale = 0.5	
		SPEED = 460
		my_timer.wait_time = 2.0
		my_timer.one_shot = true
		my_timer.start()
		currentHalth -= 3
		healthChanged.emit(currentHalth)
	elif not is_attacking and not is_firing:
		# Only play other animations if not attacking
		if not is_on_floor():
			animated_sprite.play("jump")
		elif direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")

	# Flip
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Move
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_animation_finished():
	# Only reset if we were attacking
	if is_attacking:
		is_attacking = false
	if is_firing:
		is_firing = false

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.name == "Killzone":
		currentHalth -= 1
		if currentHalth < 0:
			Engine.time_scale = 1.0
			SPEED = 230
			get_tree().reload_current_scene()
		healthChanged.emit(currentHalth)
	if area.has_method("collect"):
		area.collect()
		currentHalth += 3
		if currentHalth > maxHealth:
			currentHalth = maxHealth
		healthChanged.emit(currentHalth)
func shoot_projectile() -> void:
	if energy_ball_scene == null:
		return
	var projectile = energy_ball_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = 1 if not animated_sprite.flip_h else -1


func _on_my_timer_timeout() -> void:
	Engine.time_scale = 1.0
	SPEED = 230
