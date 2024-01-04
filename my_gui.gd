extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_quit_pressed():
	get_tree().quit()


func _on_resume_pressed():
	hide()
	get_tree().paused = false
