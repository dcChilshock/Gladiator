extends CharacterBody2D


const SPEED = 150.0  # 80.0
# const JUMP_VELOCITY = -400.0
const MAX_OBTAINABLE_HEALTH = 400.0

enum STATES { IDLE=0, DEAD, DAMAGED, ATTACKING, CHARGING }

@export var data = {
	"max_health": 100.0,  # 20hp per heart; 5 per fraction
	"health": 100.0,      # Min 60 Max 400
	"money": 0,
	"state": STATES.IDLE,
	"secondaries": [],
}

var inertia = Vector2()
var look_direction = Vector2.DOWN  # (0, 1)
var attack_direction = Vector2.DOWN
var animation_lock = 0.0  # Lock player while playing attack animation
var damage_lock = 0.0

var slash_scene = preload("res://slash.tscn")
var menu_scene = preload("res://my_gui.tscn")
var attack_sound = preload("res://Sound/slash.wav")
var damage_shader = preload("res://Effects/Take_damage.tres")
var slashsound = preload("res://Sound/slash.wav")
var menu_instance = null

@onready var p_HUD = get_tree().get_first_node_in_group("HUD")
@onready var aud_player = $AudioStreamPlayer2D
# Add and preload sounds for attack, death, hurt, coin, miniheart, charge_attack
# aud_player.stream = whatever_sound
# aud_player.play()

func get_direction_name():
	return ["right", "down", "left", "up"][
		int(round(look_direction.angle() * 2 / PI)) % 4
	]

func slash_attack():
	data.state = STATES.ATTACKING
	$AnimatedSprite2D.play("swipe_" + get_direction_name())
	attack_direction = look_direction
	var slash = slash_scene.instantiate()
	slash.position = attack_direction * 20.0
	slash.rotation = Vector2().angle_to_point(-attack_direction)
	add_child(slash)
	#aud_player.stream = slashsound
	#aud_player.play
	animation_lock = 0.2
func pickup_money(value):
	data.money += value
func pickup_health(value):
	data.health += value
	data.health = clamp(data.health, 0, data.max_health)
func _ready():
	#p_HUD.show()
	menu_instance = menu_scene.instantiate() 
	get_tree().get_root().add_child.call_deferred(menu_instance)
	menu_instance.hide()
signal health_depleted
func take_damage(dmg):
	print("lsaghfpoursg")
	if damage_lock == 0.0:
		data.health -= dmg
		data.state = STATES.DAMAGED
		damage_lock = 0.5
		animation_lock = dmg * 0.005
		# TODO: damage shader
		#$AnimatedSprite2D.material = damage_shader.duplicate()
		#$AnimatedSprite2D.material.set_shader_parameter("intensity", 0.5)
		if data.health <= 0:
			data.state = STATES.DEAD
			# TODO: play death animation & sound
			await get_tree().create_timer(0.5).timeout
			health_depleted.emit()
			
		#else:
			# TODO: play damage sound
	pass
func _physics_process(delta):
	animation_lock = max(animation_lock-delta, 0.0)
	damage_lock = max(damage_lock-delta, 0.0)
	
	if animation_lock == 0.0 and data.state != STATES.DEAD:
		if data.state == STATES.DAMAGED and max(damage_lock-delta, 0.0):
			$AnimatedSprite2D.material = null
		var direction = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		).normalized()  # Scale to 1 to prevent speed boost
		update_animation(direction)
		if direction.length() > 0:
			look_direction = direction
			velocity = direction * SPEED
		else:
			velocity = velocity.move_toward(Vector2(), SPEED)
		
		velocity += inertia
		inertia = inertia.move_toward(Vector2(), delta * 1000.0)
		move_and_slide()
		
	if data.state != STATES.DEAD:
		if Input.is_action_just_pressed("ui_accept"):
			slash_attack()
		if Input.is_action_just_pressed("ui_cancel"):
			menu_instance.global_position = self.global_position
			menu_instance.show() 
			get_tree().paused = true
func update_animation(direction):
	if data.state == STATES.IDLE:
		var a_name = "idle_down"  # Default
		if direction.length() > 0:
			look_direction = direction
			a_name = "walk_"
			if direction.x != 0:
				a_name += "side"
				$AnimatedSprite2D.flip_h = look_direction.x < 0
			elif direction.y < 0:
				a_name += "up"
			elif direction.y > 0:
				a_name += "down"
			$AnimatedSprite2D.play()
		else:
			if look_direction.x != 0:
				a_name = "idle_side"
				$AnimatedSprite2D.flip_h = look_direction.x < 0
			elif look_direction.y < 0:
				a_name = "idle_up"
			elif look_direction.y > 0:
				a_name = "idle_down"
		
		if $AnimatedSprite2D.animation != a_name:
			$AnimatedSprite2D.animation = a_name

#https://sanderfrenken.github.io/Universal-LPC-Spritesheet-Character-Generator/#?body=Body_color_light&head=Human_male_light&weapon=Longsword_alt_longsword_alt&bandana=none&headcover=none&shoulders=Epaulets_silver&bracers=Bracers_iron&gloves=none&armour=Plate_iron&belt=Leather_Belt_brown&chainmail=Chainmail_gray&sex=male&legs=Armour_iron&shoes=Armour_iron&shield=none&hat=Close_helm_steel&visor=Grated_visor_steel
#https://www.bandlab.com/
#https://opengameart.org/content/lots-of-free-2d-tiles-and-sprites-by-hyptosis

