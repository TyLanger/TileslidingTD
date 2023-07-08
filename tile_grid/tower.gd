extends Node2D

@export var arrow_scene: PackedScene

var is_on_conveyor = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_just_pressed("Space")):
		$Timer.start()


func _on_timer_timeout():
	# don't shoot while on a conveyor
	if(!is_on_conveyor):
		print("shoot")
		var arrow = arrow_scene.instantiate()
		#arrow.position = Vector2(30.0, 40.0)
		add_child(arrow)

func place_on_tile():
	is_on_conveyor = false

func place_on_conveyor():
	is_on_conveyor = true
