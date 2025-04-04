import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.tensorboard import SummaryWriter
import numpy as np
import random

class DQN(nn.Module):
    def __init__(self, input_size, output_size):
        super().__init__()
        self.fc = nn.Sequential(
            nn.Linear(input_size, 128),
            nn.ReLU(),
            nn.Linear(128, output_size)
        )

    def forward(self, x):
        return self.fc(x)

class RLAgent:
    def __init__(self, input_size, output_size):
        self.model = DQN(input_size, output_size)
        self.target_model = DQN(input_size, output_size)
        self.optimizer = optim.Adam(self.model.parameters(), lr=0.001)
        self.criterion = nn.MSELoss()

        self.memory = []
        self.gamma = 0.99
        self.epsilon = 1.0
        self.epsilon_decay = 0.995
        self.epsilon_min = 0.1
        
        # TensorBoard setup
        self.writer = SummaryWriter(log_dir="logs")

    def remember(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))
        if len(self.memory) > 10000:
            self.memory.pop(0)

    def act(self, state):
        # Exploration vs Exploitation
        if random.random() < self.epsilon:
            return random.randint(0, 3)  # Random action for exploration
        with torch.no_grad():
            state_tensor = torch.FloatTensor(state)
            q_values = self.model(state_tensor)
            return torch.argmax(q_values).item()  # Action with highest Q-value for exploitation

    def replay(self, batch_size=16):
        if len(self.memory) < batch_size:
            return

        batch = random.sample(self.memory, batch_size)
        total_loss = 0  # Accumulate loss for the batch
        for state, action, reward, next_state, done in batch:
            target = self.model(torch.FloatTensor(state))
            if done:
                target[action] = reward
            else:
                next_q = self.target_model(torch.FloatTensor(next_state))
                target[action] = reward + self.gamma * torch.max(next_q).item()

            output = self.model(torch.FloatTensor(state))
            loss = self.criterion(output, target)
            total_loss += loss.item()  # Add loss to the total for this batch

            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()

        self.epsilon = max(self.epsilon_min, self.epsilon * self.epsilon_decay)
        
        return total_loss  # Return the total loss from the batch


    def track_progress(self, reward, loss, episode):
        # Add scalar data to TensorBoard
        self.writer.add_scalar('Reward/Episode', reward, episode)
        if loss is not None:
            self.writer.add_scalar('Loss/Episode', loss, episode)
