# SnakeAI
This is a repository containing project of mine for learning reinforcement learning. The content of the project is about reinforcement learning agent playing a popular snake game. 
The environment for the reinforcement learning is made by myself following a tutorial using the Godot game engine

# Requirements
The project use these following software and libraries in order to be able to run
- Godot version 3.2.2 stable with python binding
- Pytorch Stable (2.4.0) CUDA 11.8
- Numpy latest version

# Resources
I will include some of the source and resources that I use to build this project, which is as follow,
- Project inspiration: The project was inspired by a showcase video made by xen-42 which can be viewed in the following link, https://www.youtube.com/watch?v=v7EJX38gG-E&t=26s
- Godot with python binding installation: The installation process of the Godot game engine that enables pyhton binding can be viewed in the following link, https://www.youtube.com/watch?v=IafLArxKVjY&t=558s
- Snake game tutorial: To create the environment I used a tutorial video by Coding With Russ in the following link, https://www.youtube.com/watch?v=DlRP-UBR-2A&t=35s

# Branch navigation
Currently the main branch is purely for the snake game without the reinforcement learning is involved. The other branches with prefix "ai_update" contains the modification to accomodate the reinforcement learning system.
Each branch with "ai_update" prefix has the similar neural network architecture which is DQN and environment configuration but with different approach which can be explaines as follow:
-  "ai_update": Naive approach where the obseration consist of the situation of the entire environments and pass it to a usual fully connected layer.
-  "ai_update-v2": Heuristic based approach where the observation consists of information in the surrounding of the snake where the snake head is the center along with one-hot encoded current direction of the snake and the direction to the food
-  "ai_update-v3": CNN based approach where the observation consist of stacked frame and where each frame contains the 'screenshot' or 'the projection' of the environment. It also utilizes convolutional network to train the agent.
Side note: The only approach that currently work well is in the "ai_update-v2" branch
