extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@export var next_level ="pathfindingtest"

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		var lvl = "res://" + next_level + ".tscn"
		get_tree().change_scene_to_file(lvl)
