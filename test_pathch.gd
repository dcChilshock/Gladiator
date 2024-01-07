extends CharacterBody2D

const speed = 100 
var dir : Vector2
func _physics_process(_delta: float):
	velocity = dir * speed
	move_and_slide()

func _unhandled_input(event: InputEvent):
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.y = Input.get_axis("ui_up", "ui_down")
	dir = dir.normalized()
