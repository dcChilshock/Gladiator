extends CharacterBody2D
# figure out how to makw Ai states work with pathfiding

const speed = 60.0
var MAX_HEALTH: float = 30.0
var  HEALTH = MAX_HEALTH
var DAMAGE = 10.0
var AI_STATE = STATES.IDLE
				# 0  1 up   2down 3left 4right 5         6        7        8         9
enum STATES { IDLE=0, UP, DOWN, LEFT, RIGHT, UPLEFT, UPRIGHT, DOWNLEFT, DOWNRIGHT, DAMAGED, CHASE}

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
	Vector2.ZERO,
	Vector2.ZERO,
	]

var state_animations = [
	"", 
	"move_up", 
	"move_down",
	"move_side", #left
	"move_side", #right
	
	"move_side", #NW up left
	"move_side", # NE up right
	
	"move_side", #down left
	"move_side", #down right
	"",
	"",
]
var inertia = Vector2()
var ai_timer_max = 0.5
var ai_timer = ai_timer_max - randi() % 5
var damage_lock = 0.0 
var animation_lock = 0.0 
var knockback = 120.0
var vision_distance = 40.0
var money_value = 5.0

signal recovered

@export var player: Node2D
@onready var raycastM = "$raycastM"
@onready var raycastN = "$raycastN"
@onready var raycastS = "$raycastS"
@onready var anim_player = $AnimatedSprite2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var damage_shader = "res://EFFECTS/Take_damage.tres"
@onready var aud_player = $AudioStreamPlayer2D
@onready var death_sound = "res://Sound/OnlineSound.net SFX hitHurt.wav"
@onready var hit_

func _physics_process(delta):
	animation_lock = max(animation_lock-delta, 0.0)
	damage_lock = max(damage_lock-delta, 0.0)
	if AI_STATE == STATES.CHASE:
		var dir = to_local(nav_agent.get_next_path_position()).normalized()
		velocity = dir * speed
		move_and_slide()
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
	#var animation = state_animations[int(AI_STATE)]
	#if animation and not anim_player.is_playing():
		#anim_player.play(animation)
		#if AI_STATE == STATES.IDLE and anim_player.is_playing():
			#anim_player.stop()

func makepath():
	nav_agent.target_position = player.global_position

func _on_timer_timeout():
	makepath()

func _on_chaserange_body_entered(body):
	if body.is_in_group("player"):
		AI_STATE = STATES.CHASE

func take_damage(dmg, attacker=null):
	if damage_lock == 0.0:
		AI_STATE = STATES.DAMAGED
		HEALTH -= dmg
		damage_lock =0.2
		animation_lock = 0.2
		#damage intensity plus shader
		#var dmg_intensity = clamp(1.0-((HEALTH+0.01)/MAX_HEALTH), 0.1, 0.8)
		#$AnimatedSprite2D.material = damage_shader.duplicate()
		#$AnimatedSprite2D.material.set_shader_parameter("intensity", dmg_intensity)
		
		if HEALTH <= 0:
			#aud_player.stream = death_sound 
			#aud_player.play() 
			#await aud_player.finished 
			queue_free()
			
		#else:
			#if attacker != null:
				#AI_STATE = STATES.CHASE
	pass
