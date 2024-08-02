from godot import exposed, export, Node
from godot import *

import torch as T
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
import numpy as np

class DQN(nn.Module):
	def __init__(self, lr, input_dims, fc1_dims, fc2_dims, fc3_dims, n_actions):
		super(DQN, self).__init__()
		self.fc1_dims = fc1_dims
		self.fc2_dims = fc2_dims
		self.fc3_dims = fc3_dims
		self.input_dims = input_dims
		self.n_actions = n_actions
		self.fc1 = nn.Linear(self.input_dims, self.fc1_dims)
		self.fc2 = nn.Linear(self.fc1_dims, self.fc2_dims)
		self.fc3 = nn.Linear(self.fc2_dims, self.fc3_dims)
		self.fc4 = nn.Linear(self.fc3_dims, self.n_actions)
		self.opt = optim.Adam(self.parameters(), lr=lr)
		self.loss = nn.MSELoss()
		self.device = ('cuda' if T.cuda.is_available() else 'cpu')
		self.to(self.device)
	
	def forward(self, state):
		x = F.relu(self.fc1(state))
		x = F.relu(self.fc2(x))
		x = F.relu(self.fc3(x))
		actions = self.fc4(x)
		
		return actions

class AI_Brain():
	def __init__(self, gamma, eps, lr, input_dims, batch_size, n_actions,
		max_mem_size=100000, eps_end=0.01, eps_dec=0.00005):
			self.gamma = gamma
			self.eps = eps
			self.lr = lr
			self.input_dims = input_dims
			self.batch_size = batch_size
			self.action_space = [i for i in range(n_actions)]
			self.mem_size = max_mem_size
			self.batch_size = batch_size
			self.mem_cntr = 0
			self.eps_end = eps_end
			self.eps_dec = eps_dec
			
			self.Q_eval = DQN(self.lr, n_actions=n_actions, input_dims=self.input_dims,
								fc1_dims = 512, fc2_dims = 512, fc3_dims = 512)
			self.state_memory = np.zeros((self.mem_size, self.input_dims), dtype=np.float32)
			self.new_state_memory = np.zeros((self.mem_size, self.input_dims), dtype=np.float32)
			
			self.action_memory = np.zeros(self.mem_size, dtype=np.int32)
			self.reward_memory = np.zeros(self.mem_size, dtype=np.float32)
			self.terminal_memory = np.zeros(self.mem_size, dtype=np.bool_)
			
	def store_transition(self, state, action, reward, state_, done):
		index = self.mem_cntr % self.mem_size
		self.state_memory[index] = state
		self.new_state_memory[index] = state_
		self.action_memory[index] = action
		self.reward_memory[index] = reward
		self.terminal_memory[index] = done
		
		self.mem_cntr += 1
	
	def do_action(self, obs):
		if np.random.random() > self.eps:
			state = T.tensor(np.array([obs]), dtype=T.float32).to(self.Q_eval.device)
			actions = self.Q_eval.forward(state)
			action = int(T.argmax(actions).item())
		else:
			action = int(np.random.choice(self.action_space))
		
		return action
	
	def learn(self):
		if self.mem_cntr < self.batch_size:
			return
		
		self.Q_eval.opt.zero_grad()
		
		max_mem = min(self.mem_cntr, self.mem_size)
		batch = np.random.choice(max_mem, self.batch_size, replace=False)
		
		batch_index = np.arange(self.batch_size, dtype=np.int32)
		
		state_batch = T.tensor(self.state_memory[batch]).to(self.Q_eval.device)
		new_state_batch = T.tensor(self.new_state_memory[batch]).to(self.Q_eval.device)
		reward_batch = T.tensor(self.reward_memory[batch]).to(self.Q_eval.device)
		terminal_batch = T.tensor(self.terminal_memory[batch]).to(self.Q_eval.device)
		
		action_batch = self.action_memory[batch]
		
		q_eval = self.Q_eval.forward(state_batch)[batch_index, action_batch]
		q_next = self.Q_eval.forward(new_state_batch)
		q_next[terminal_batch] = 0.0
		
		q_target = reward_batch + self.gamma * T.max(q_next, dim=1)[0]
		
		loss = self.Q_eval.loss(q_target, q_eval).to(self.Q_eval.device)
		loss.backward()
		self.Q_eval.opt.step()
		
		self.eps = self.eps - self.eps_dec if self.eps > self.eps_end else self.eps_end

@exposed
class AI_Agent(Node):
	def _ready(self):
		self.agent = AI_Brain(gamma=0.99, eps=1.0, lr=0.001, input_dims=(18*18+8),
						n_actions=3, batch_size=500)
	
	def get_action(self, obs):
		#Flatten the observation
		o = np.array(obs, dtype=np.int32).flatten()
		
		#Pass the observation to the brain
		action = self.agent.do_action(o)
		return action
	
	def store_transition(self, obs, action, reward, obs_, done):
		#Flatten the observation
		o = np.array(obs, dtype=np.int32).flatten()
		o_ = np.array(obs_, dtype=np.int32).flatten()
		
		#Store the transition to the brain
		self.agent.store_transition(o, action, reward, o_, done)
	
	def learn(self):
		self.agent.learn()
	
	def get_epsilon(self):
		return self.agent.eps
