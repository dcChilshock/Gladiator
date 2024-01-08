extends CharacterBody2D

const SPEED = 50

var MAX_HEALTH: float = 30.0
var  HEALTH = MAX_HEALTH
var DAMAGE = 10.0
var AI_STATE = STATES.IDLE

var inertia = Vector2()
var ai_timer_max = 0.5
var ai_timer = ai_timer_max - randi() % 5
var damage_lock = 0.0 
var animation_lock = 0.0 
var knockback = 120.0
var vision_distance = 40.0
var money_value = 5.0

enum STATES { IDLE=0, NORTH, SOUTH, WEST, EAST, NORTH_W, NORTH_E, SOUTH_W, SOUTH_E, DAMAGED}

var state_directions = [
	Vector2.ZERO,
	Vector2.UP, #NORTH
	Vector2.DOWN, #SOUTH
	Vector2.LEFT, #WEST
	Vector2.RIGHT, #EAST
	Vector2(-1,-1).normalized(), #NW
	Vector2(1,-1).normalized(), #NE
	Vector2(-1,1).normalized(),#SW
	Vector2(1,1).normalized(), #SE
	Vector2.ZERO
]

var state_animations = [
	"", 
	"move_up",
	"move_down",
	"e_walk_left",
	"move_side",
	
	"e_walk_left",
	"move_side",
	
	"e_walk_left",
	"move_side",
	""
]

@export var player: Node2D

#@onready var anim_player = $AnimatedSprite2D
#@onready var raycastN =$RayCastN
#@onready var raycastM =$RayCastW

#@onready var raycastS =$RayCastS
#@onready var aud_player = $AudioStreamPlayer2D

signal recovered

#var drops = ["drop_heart"]
#var coin_scene = preload("res://entities/coin.tscn")
#var heart_scene = preload("res://entities/mini_heart.tscn")
#var hit_sound = preload("res://sounds/OnlineSound.net SFX hitHurt.wav")
#var death_sound = preload("res://sounds/OnlineSound.net SFX hitHurt.wav")
#var damage_shader = preload("res://assets/shaders/Take_damage.tres")

func vec2_offset():
	return Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
func drop_scene(item_scene):
	item_scene.global_position = self.global_position + vec2_offset()
	get_tree().current_scene.add_child(item_scene)
func drop_heart():
	#var heart = heart_scene.instantiate()
	#drop_scene(heart)
	pass
func drop_item():
	#var num_drops = randi() % 3 + 1 
	#for i in range(num_drops):
		#var rnd_drop = drops[randi() % drops.size()]
		#call_deferred(rnd_drop)
		pass

func turn_toward_player_location(location: Vector2):
	
	var dir_to_player = (location - global_position).normalized()
	velocity = dir_to_player * (SPEED)
	var closest_angle = INF 
	var closest_state = STATES.IDLE
	for i in range(1, 5):
		var state_dir = state_directions[i]
		var angle_diff = abs(state_dir.angle_to(dir_to_player))
		if angle_diff < closest_angle:
			closest_angle = angle_diff
			closest_state = STATES.values()[i]
	AI_STATE = closest_state
func take_damage(dmg, attacker=null):
	if damage_lock == 0.0:
		AI_STATE = STATES.DAMAGED
		HEALTH -= dmg
		damage_lock =0.2
		animation_lock = 0.2
		#damage intensity plus shader
		var dmg_intensity = clamp(1.0-((HEALTH+0.01)/MAX_HEALTH), 0.1, 0.8)
		#$AnimatedSprite2D.material = damage_shader.duplicate()
		#$AnimatedSprite2D.material.set_shader_parameter("intensity", dmg_intensity)
		
		if HEALTH <= 0:
			drop_item()
			#aud_player.stream = death_sound 
			#aud_player.play() 
			#await aud_player.finished 
			queue_free()
		else:
			if attacker != null:
				var location = attacker.global_position
				await recovered
				turn_toward_player_location(location)
	pass

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D

func _ready():
	makepath()

func _physics_process(delta: float): 
	animation_lock = max(animation_lock-delta, 0.0)
	damage_lock = max(damage_lock-delta, 0.0)
	#if int(AI_STATE) >= 1 and int(AI_STATE) <= 8:
		#var raydir = state_directions[int(AI_STATE)]
		#raycastM.target_position = raydir * vision_distance
		#raycastN.target_position = \
			#raydir.rotated(deg_to_rad(-45)).normalized() * vision_distance
		#raycastS.target_position = \
			#raydir.rotated(deg_to_rad(-45)).normalized() * vision_distance
			
	if animation_lock == 0.0:
		if AI_STATE == STATES.DAMAGED:
			$AnimatedSprite2D.material = null
			AI_STATE = STATES.IDLE
			recovered.emit()
		for player in get_tree().get_nodes_in_group("player"):
			if $attack_hitbox.overlaps_body(player):\
				if player.damage_lock == 0.0:
					player.inertia = (player.global_position - global_position).normalized()*knockback
					player.take_damage(DAMAGE)
			else: 
				return
				#if player.data.state != player.STATES.DEAD:
					#if (raycastM.is_colliding() and raycastM.get_collider() == player) or \
						#(raycastN.is_colliding() and raycastN.get_collider() == player) or \
						#(raycastS.is_colliding() and raycastS.get_collider() == player):
							#turn_toward_player_location(player.global_position)
		ai_timer = clamp(ai_timer-delta , 0.0 , ai_timer_max)
		if ai_timer == 0.0:
			if AI_STATE == STATES.IDLE: 
				var rnd_mov = randi() % 4
				AI_STATE = STATES.values()[rnd_mov+1]
			
			else:
				AI_STATE = STATES.IDLE
			ai_timer = ai_timer_max
		var direction = state_directions[int(AI_STATE)]
		velocity = direction * SPEED
	
		var animation = state_animations[int(AI_STATE)]
		#if animation and not anim_player.is_playing():
			#anim_player.play(animation)
	
		#if AI_STATE == STATES.IDLE and anim_player.is_playing():
			#anim_player.stop()
	velocity += inertia
	
	inertia = inertia.move_toward(Vector2(), delta * 1000.0)
	var dir = to_local(nav_agent.get_next_path_position()).normalized()
	velocity = dir * SPEED
	move_and_slide()

func makepath() -> void:
	nav_agent.target_position = player.global_position

func _on_timer_timeout():
	makepath()
