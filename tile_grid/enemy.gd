extends Node2D

var can_move = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(can_move):
		position = position + Vector2(-1.0, 0.0)

func set_move(new_move):
	can_move = new_move
