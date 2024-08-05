extends Node

export(PackedScene) var snake_segment : PackedScene
export(PackedScene) var snake_head : PackedScene

export(PackedScene) var fud_scene : PackedScene

export(bool) var allow_input : bool = false

#Other variables
var offset : int = 32
var game_end : bool = true

#Score variables
var score : int
var env_started : bool = true

#Cell variables
var cells = 16
var cell_size = 64

#Snake variables
var snake_old : Array
var snake_data : Array
var snake : Array

#Movement variables
var start_pos : Vector2
enum Dir {
	UP, RIGHT, DOWN, LEFT
}
var cur_dir
var cur_move : Vector2
var can_move : bool = false

#Fud variables
var fud_obj
var fud_pos : Vector2
var regen_fud : bool = true
var fud_spawned : bool = false

#Time variables
var time_passed : float = 0
var wait_time : float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

#Return the vector direction based on the direction enumeration
func _move(_movement) -> Vector2:
	if _movement == Dir.UP:
		return Vector2(0, -1)
	elif _movement == Dir.RIGHT:
		return Vector2(1, 0)
	elif _movement == Dir.DOWN:
		return Vector2(0, 1)
	else:
		return Vector2(-1, 0)

#Starting a new game
func new_game():
	get_tree().paused = false
	game_end = false
	score = 0
	$HUD.get_node("ScoreLabel").text = "Score: " + str(score)
	can_move = true
	cur_dir = Dir.UP
	generate_snake()
	generate_food()

#Function to generate food
func generate_food():
	regen_fud = false
	fud_spawned = true
	fud_pos = Vector2(randi() % (cells-1) + 1, randi() % (cells-1) + 1)
	#fud_pos = Vector2(10, 4)
	fud_obj = fud_scene.instance()
	fud_obj.position = (fud_pos * cell_size) - Vector2(offset, offset)
	add_child(fud_obj)

#Function to move food
func move_food():
	while regen_fud and fud_spawned:
		fud_pos = Vector2(randi() % (cells-1) + 1, randi() % (cells-1) + 1)
		regen_fud = false
		for _pos in snake_data:
			if fud_pos == _pos:
				regen_fud = true
				break
	
	fud_obj.position = (fud_pos * cell_size) - Vector2(offset, offset)

#Function to generate a new snake
func generate_snake():
	snake_old.clear()
	snake_data.clear()
	snake.clear()
	
	start_pos = Vector2(randi() % (cells-1) + 1, 8)
	add_segment(start_pos, snake_head)
	
	for i in range(1, 4):
		add_segment(start_pos + Vector2(0, i), snake_segment)

#Function to add a segment on the snake
func add_segment(pos, segment_obj):
	snake_data.append(pos)
	var SnakeSegment = segment_obj.instance()
	SnakeSegment.position = (pos * cell_size) - Vector2(offset, offset)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)

#Function to define the movement of the snake
func move_snake():
	
	if can_move and allow_input: #Choosing a direction for the snake if input is allowed
		if Input.is_action_just_pressed("rotate_left"):
			cur_dir = int(cur_dir)-1
			can_move = false
		elif Input.is_action_just_pressed("rotate_right"):
			cur_dir = int(cur_dir)+1
			can_move = false
		
	if cur_dir > Dir.LEFT:
		cur_dir = Dir.UP
	elif cur_dir < Dir.UP:
		cur_dir = Dir.LEFT
		
	cur_move = _move(cur_dir)

	can_move = true
	
	snake_old = [] + snake_data
	snake_data[0] += cur_move
	var end = check_self_eaten()
	if not end:
		for i in range(len(snake_data)):
			if i > 0:
				snake_data[i] = snake_old[i-1]
			snake[i].position = (snake_data[i] * cell_size) - Vector2(offset, offset)
	
	#print_coor(snake_data)
	check_out_of_bounds()
	check_food_eaten()

#Function to check wheter the snake is out of bound
func check_out_of_bounds():
	if snake_data[0].x <= 0 or snake_data[0].x > cells or snake_data[0].y <= 0 or snake_data[0].y > cells:
		end_game()

#Function to check whether the snake eat itself
func check_self_eaten():
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()
			return true

#Function to check whether to regenerate food or not
func check_food_eaten():
	if snake_data[0] == fud_pos:
		score += 1
		regen_fud = true #Set the regenerate food to true
		$HUD.get_node("ScoreLabel").text = "Score: " + str(score) #Update the score
		move_food()
		
		add_segment(snake_old[-1], snake_segment)
		
#End game function
func end_game():
	#get_tree().paused = true
	game_end = true
	print("Game over")
	
	#Free up some object from the memory
	for snak in snake:
		if snak:
			snak.queue_free()
	fud_obj.queue_free()

#----------------Debugging function------------------
func print_coor(data):
	var report = ""
	for c in data:
		report = report + str(c) + " "
	print(report)
