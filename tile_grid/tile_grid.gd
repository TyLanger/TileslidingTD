extends Node2D

@export var tile_scene: PackedScene
@export var tower_scene: PackedScene

var offset = 96
var tile_width = 80
var grid

var top_tower_conveyor
var bot_tower_conveyor

# 96 - 80/2 = 56
# 56 to 136 is the first tile
# 136 to 216 is the second tile
# mouse - 56 / 80 is tile number

var dragging = false
var col_drag = 0
var og_click_pos

class ConveyorTower:
	var tower: Node
	var exists: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	grid = []
	for i in 14:
		var row = []
		for j in 7:
			
			var tile = tile_scene.instantiate()
			
		
			# tile is 80px
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
	
	top_tower_conveyor = []
	bot_tower_conveyor = []
	for i in 5:
		var ct = ConveyorTower.new()
		ct.exists = false
		top_tower_conveyor.append(ct)
		var ct2 = ConveyorTower.new()
		ct2.exists = false
		bot_tower_conveyor.append(ct2)
	spawn_tower(5, 0)
	spawn_tower(1, 6)
	spawn_tower(5, 6)


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
		drop_towers(col_drag)
		
	if(dragging):
		change_col(col_drag)
		move_towers(col_drag)
	
func _input(event):
   # Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		#print("Mouse Click/Unclick at: ", event.position)
		pass
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		pass



func spawn_tower(x, y):
	var tower = tower_scene.instantiate()
	tower.position = Vector2(offset + tile_width * x, offset + tile_width * y)
	tower.modulate = Color(0.3, 0.8, 0.3)
	tower.place_on_conveyor()
	if(y==0):
		var conveyor = ConveyorTower.new()
		conveyor.exists = true
		conveyor.tower = tower
		top_tower_conveyor[x-1] = conveyor
	elif(y==6):
		var conveyor = ConveyorTower.new()
		conveyor.exists = true
		conveyor.tower = tower
		bot_tower_conveyor[x-1] = conveyor
	add_child(tower)

func move_towers(col_index):
	if(top_tower_conveyor[col_index-1].exists):
		var mouse_diff = get_viewport().get_mouse_position().y - og_click_pos.y
		var height = offset + tile_width * 0 + mouse_diff
		var new_pos = Vector2(offset + tile_width * col_index, height)
		top_tower_conveyor[col_index-1].tower.position = new_pos
	if(bot_tower_conveyor[col_index-1].exists):
		var mouse_diff = get_viewport().get_mouse_position().y - og_click_pos.y
		var height = offset + tile_width * 6 + mouse_diff
		var new_pos = Vector2(offset + tile_width * col_index, height)
		bot_tower_conveyor[col_index-1].tower.position = new_pos

func drop_towers(col_index):
	
	var top_tower_transfer = false
	# add as a child to the tile you're over
	if(top_tower_conveyor[col_index-1].exists):
		var pos = top_tower_conveyor[col_index-1].tower.position
		var index: int = (pos.y - (offset - (tile_width/2))) / tile_width
		# over a tile
		if(index>0 && index<6):
			top_tower_conveyor[col_index-1].exists = false
			top_tower_conveyor[col_index-1].tower.position = Vector2(0.0, 0.0)
			top_tower_conveyor[col_index-1].tower.place_on_tile()
			remove_child(top_tower_conveyor[col_index-1].tower)
			grid[col_index][index].add_child(top_tower_conveyor[col_index-1].tower)
		elif(index==0 || index==6):
			# if over either conveyor, return home
			# probably the easiest way to handle this
			top_tower_conveyor[col_index-1].tower.position = Vector2(offset + tile_width * col_index, offset + tile_width * 0)
		elif(index==6):
			# need to do this after the bot tower has a chance to stick to a tile
			#bot_tower_conveyor
			top_tower_transfer = true
		elif(index<0 || index>6):
			top_tower_conveyor[col_index-1].exists = false
			top_tower_conveyor[col_index-1].tower.queue_free()
			
		# what to do when over a conveyor?
		# place back on it probs
		# what if another tower is there? Which one dies?
		# you'd be moving both so they can't be on top of one another
		# what to do when past the conveyors?
		# delete it
	
	var bot = bot_tower_conveyor[col_index-1]
	if(bot.exists):
		var pos = bot.tower.position
		var index: int = (pos.y - (offset - (tile_width/2))) / tile_width
		if(index>0 && index<6):
			bot_tower_conveyor[col_index-1].exists = false
			bot.tower.position = Vector2.ZERO
			bot.tower.place_on_tile()
			remove_child(bot.tower)
			grid[col_index][index].add_child(bot.tower)
		elif(index==6 || index==0):
			bot_tower_conveyor[col_index-1].tower.position = Vector2(offset + tile_width * col_index, offset + tile_width * 6)
		elif(index==0):
			# swap conveyors
			# if another tower exists on the other conveyor, it will either be out of bounds and deleted
			# or on a tile by now
			# or it was over top of an existing tower and I don't know what behaviour that has yet...
			pass
		elif(index<0 || index>6):
			bot_tower_conveyor[col_index-1].exists = false
			bot_tower_conveyor[col_index-1].tower.queue_free()

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
