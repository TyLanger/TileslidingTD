extends Node2D

@export var tile_scene: PackedScene

var offset = 96
var tile_width = 80
var grid

# 96 - 80/2 = 56
# 56 to 136 is the first tile
# 136 to 216 is the second tile
# mouse - 56 / 80 is tile number

var dragging = false
var col_drag = 0
var og_click_pos

# Called when the node enters the scene tree for the first time.
func _ready():
	grid = []
	for i in 14:
		var row = []
		for j in 7:
			
			var tile = tile_scene.instantiate()
			
		
			# tile is 128px
			tile.position = Vector2(offset + tile_width * i, offset + tile_width * j)
			#tile.modulate = Color(i/10.0, j/10.0, 1.0-(i+j)/20.0)
			if(i==0 || j==0 || i==13 || j==6 || i==6 || i==7):
				tile.modulate = Color(1.0, 0.6, 0.6)
			else:
				tile.modulate = Color(0.8 + j/10.0, 0.8+j/10.0, 0.8+j/10.0)
			add_child(tile)
			row.append(tile)
			#grid[i][j] = tile
		grid.append(row)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_just_pressed("mouse_left")):
		var mouse = get_viewport().get_mouse_position()
		print("click at: ", mouse)
		if(is_click_in_bounds(mouse)):
			var col_index = get_tile_index(mouse)
			#print("on tile: ", col_index)
			# if can drag
			if(col_index==0 || col_index==13 || col_index==6 || col_index==7):
				pass
			else:
				dragging = true
				col_drag = col_index
				og_click_pos = mouse
		else:
			print("Out of bounds")
	elif(Input.is_action_just_released("mouse_left")):
		var mouse = get_viewport().get_mouse_position()
		print("unclick at: ", mouse)
		dragging = false
		reset_col(col_drag)
		
	if(dragging):
		change_col(col_drag)
	
func _input(event):
   # Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		#print("Mouse Click/Unclick at: ", event.position)
		pass
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		pass

func change_col(col_index):
	for i in range(1,6):
		#grid[col_index][i].modulate = Color(0.5 + i/10.0, 0.5 + i/10.0, 0.5 + i/10.0)
		var mouse_diff = get_viewport().get_mouse_position().y - og_click_pos.y
		var height = offset + tile_width * i + mouse_diff
		var new_pos = Vector2(offset + tile_width * col_index, height)
		
			#grid[col_index][i].modulate = Color(0.9 + i/10.0, 0.3 + i/10.0, 0.3 + i/10.0)
			
		if(is_pos_above_bounds(new_pos)):
			#swap_tiles_above(col_index)
			var adjusted_height = offset + tile_width * i + mouse_diff + tile_width * 5
			grid[col_index][i].position = Vector2(offset + tile_width * col_index, adjusted_height)
		elif(is_pos_below_bounds(new_pos)):
			#swap_tiles_below(col_index)
			var adjusted_height = offset + tile_width * i + mouse_diff - tile_width * 5
			grid[col_index][i].position = Vector2(offset + tile_width * col_index, adjusted_height)
		else:
			grid[col_index][i].position = new_pos
		# modulo somehow
		# if height > max, height = min
		# if height < min, height = max
		
func reset_col(col_index):
	# bug scenarios
	# drag down out of bounds. The last tile index is >5
	# drag up out of bounds. Multiple indicies are 0
	# loop over all indicies. If any are 0, error. If any are 6, error
	# if any are 0, they should be 1,2,3,4,5
	# if any are 6, they should be 1,2,3,4,5
	
	# temp col to copy/store tiles
	# so they aren't swapped while being iterated over
	var temp_col = []
	temp_col.resize(5)
	var double_wrap = false
	
	for i in range(1,6):
		var pos = grid[col_index][i].position
		var index: int = (pos.y - (offset - (tile_width/2))) / tile_width
		if(index==0 || index>5):
			double_wrap = true
			break
	
	if(double_wrap):
		for i in range(1,6):
			var pos = grid[col_index][i].position
			var anchor_y_pos = offset + tile_width * i
			grid[col_index][i].position = Vector2(pos.x, anchor_y_pos)
	else:
		for i in range(1,6):
			#grid[col_index][i].modulate = Color(0.9 + i/10.0, 0.9 + i/10.0, 0.9 + i/10.0)
			#grid[col_index][i].position = Vector2(offset + tile_width * col_index, offset + tile_width * i)
			# have they moved?
			# want to save this new pos when they are dropped
			var pos = grid[col_index][i].position
			var index: int = (pos.y - (offset - (tile_width/2))) / tile_width
			#print("index: ", index)
			var anchor_y_pos = offset + tile_width * index
			grid[col_index][i].position = Vector2(pos.x, anchor_y_pos)
			temp_col[index-1] = grid[col_index][i]
		# if you double wrap, the tiles are already in the right order
		for i in 5:
			grid[col_index][i+1] = temp_col[i]



func swap_tiles_above(col_index):
	#dragging up, the top tile is out of bounds, wrap around to the bottom
	var temp = grid[col_index][1]
	for i in range(1,5):
		grid[col_index][i] = grid[col_index][i+1]
	grid[col_index][5] = temp
	
func swap_tiles_below(col_index):
	#dragging down, bottom tile is out of bounds
	# 4 goes to 5
	# 3 goes to 4
	# 2 goes to 3
	# 1 goes to 2
	# 5 goes to 1
	
	var temp = grid[col_index][5]
	for i in range(1,5):
		grid[col_index][5-i] = grid[col_index][5-i+1]
	grid[col_index][1] = temp

func get_tile_index(mouse):
	var tile_index: int = (mouse.x - (offset - (tile_width/2))) / tile_width
	return tile_index

# for the inner 5x5 grid
func is_pos_above_bounds(pos):
	return (pos.y < offset - (tile_width / 2) + tile_width * 1)

# for the inner 5x5 grid
func is_pos_below_bounds(pos):
	return (pos.y > offset - (tile_width / 2) + tile_width * 6)

func is_click_in_bounds(mouse):
	if(mouse.x < offset - (tile_width / 2)):
		return false
	elif(mouse.x > offset - (tile_width / 2) + tile_width * 14):
		return false
	elif(mouse.y < offset - (tile_width / 2)):
		return false
	elif(mouse.y > offset - (tile_width / 2) + tile_width * 7):
		return false
	return true
