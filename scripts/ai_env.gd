extends Node

#Outside variables
onready var ai_agent = $AI_Agent
onready var snake_game = $SnakeGame

#AI variables
var new_observation
var last_observation
var done = false
var episodes : int = 0

var scores = []
var eps_history = []
var total_score : float = 0

#Game variables
var prev_score : int = 0
var show : bool = false

var tick_time : float = 0.0
var tick_length : float = 0.1

#First initialization
func _ready():
	last_observation = get_observation()

#Function to get what the heck is happening on the game
func get_observation():
	
	#Acquire observation where the head of the snake is the center
	var tiles = []
	tiles.resize(9)
	for i in range(9):
		tiles[i] = []
		tiles[i].resize(9)
		for j in range(9):
			tiles[i][j] = 0
	
	var snake_data = snake_game.snake_data
	var fud_pos = snake_game.fud_pos
	
	var x_min = snake_data[0][0] - 4
	var x_max = snake_data[0][0] + 4
	
	var y_min = snake_data[0][1] - 4
	var y_max = snake_data[0][1] + 4
	
	for i in range(x_min, x_max + 1):
		for j in range(y_min, y_max + 1):
			if i <= 0 or j <= 0 or i > snake_game.cells or j > snake_game.cells:
				tiles[i - x_min][j - y_min] = 1
	
	for s in snake_data:
		if s[0] >= x_min and s[0] <= x_max and s[1] >= y_min and s[1] <= y_max:
			tiles[s[0] - x_min][s[1] - y_min] = 1
	
	if fud_pos.x >= x_min and fud_pos.x <= x_max and fud_pos.y >= y_min and fud_pos.y <= y_max:
		tiles[fud_pos.x - x_min][fud_pos.y - y_min] = 1
	
	var observation = []
	
	for i in range(9):
		for j in range(9):
			if i != 2 or j != 2:
				observation.append(tiles[i][j])
	
	#Append the clue of direction of fud
	observation.append(1 if snake_data[0][0] < snake_game.fud_pos.x else 0)
	observation.append(1 if snake_data[0][0] > snake_game.fud_pos.x else 0)
	observation.append(1 if snake_data[0][1] < snake_game.fud_pos.y else 0)
	observation.append(1 if snake_data[0][1] > snake_game.fud_pos.y else 0)
	
	#Append the direction of the
	observation.append(1 if snake_game.cur_dir == snake_game.Dir.UP else 0)
	observation.append(1 if snake_game.cur_dir == snake_game.Dir.RIGHT else 0)
	observation.append(1 if snake_game.cur_dir == snake_game.Dir.DOWN else 0)
	observation.append(1 if snake_game.cur_dir == snake_game.Dir.LEFT else 0)
	
	return observation

#Main loop
func _process(delta):
	if done:
		print("Evaluating--------------")
		var avg_score = 0
		scores.append(total_score)
		eps_history.append(ai_agent.get_epsilon)
		avg_score = average(scores.slice(scores.size()-100, scores.size(), 1, false))
		
		print('episode %d ' % (episodes + 1), 'score %.2f ' % total_score,
			'average score %.2f ' % avg_score,
			'epsilon %.2f ' % ai_agent.get_epsilon())
		
		#Reset everything
		total_score = 0
		done = false
		snake_game.new_game()
		last_observation = get_observation()
		prev_score = 0
		
		show = (true if (episodes % 100 == 0) or (avg_score > 200) else false)
		episodes += 1
		return
	
	if show: #Show the result of the current AI in real playtime
		if tick_time > tick_length:
			tick_time = 0.0
			play_game()
		else:
			tick_time += delta
			return
		
		if not show:
			snake_game.new_game()
			last_observation = get_observation()
			
	else: #Train the AI
		env_step()

#Function for the AI to take a step on the environment
func env_step():
	prev_score = snake_game.score
	var prev_dist = manh_dist(Vector2(snake_game.snake_data[0][0], snake_game.snake_data[0][1]), snake_game.fud_pos)
	#Choose an action
	var action = ai_agent.get_action(last_observation)
	
	var old_dir = snake_game.cur_dir
	var new_dir = old_dir + (action - 1)
	
	#Send the action to the game
	snake_game.cur_dir = new_dir
	snake_game.move_snake()
	
	#Get the new observation
	new_observation = get_observation()
	
	done = snake_game.game_end
	
	var cur_dist = manh_dist(Vector2(snake_game.snake_data[0][0], snake_game.snake_data[0][1]), snake_game.fud_pos)
	
	#Reward calculation
	var reward = 0
	if done: #Snake ded
		reward -= 100
	if snake_game.score > prev_score: #Snake ate food
		reward += 20
	
	#Reward based in the distance to the food
	if cur_dist < prev_dist: 
		reward += 0.8
	elif cur_dist >= prev_dist:
		reward -= 0.2
	
	#Punish for eating itself
	for i in range(1, len(snake_game.snake_data)):
		if snake_game.snake_data[0] == snake_game.snake_data[i]:
			print("chk")
			reward -= 300
			break
	
	reward -= 0.2
	
	total_score += reward
	
	#Store transition and learn
	ai_agent.store_transition(last_observation, action, reward, new_observation, done)
	ai_agent.learn()
	
	#Set the new observation as the last observation
	last_observation = new_observation

#Function for the AI to play the game
func play_game():
	var action = ai_agent.get_action(last_observation)
	
	var old_dir = snake_game.cur_dir
	var new_dir = old_dir + (action - 1)
	
	snake_game.cur_dir = new_dir
	snake_game.move_snake()
	
	new_observation = get_observation()
	
	show = not snake_game.game_end
	last_observation = new_observation

func average(arr):
	if arr.size() == 0:
		return 0
	var sum = 0.0
	for i in arr:
		sum += i
	return sum / arr.size()

func eucl_dist(a, b):
	var dx = a.x - b.x
	var dy = a.y - b.y
	
	return sqrt((dx * dx) + (dy * dy))

func manh_dist(a, b):
	var dx = a.x - b.x
	var dy = a.y - b.y
	return (abs(dx) + abs(dy))

