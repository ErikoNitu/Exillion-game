import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.tensorboard import SummaryWriter
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
        out = self.fc(x)
        # Normalize the output to get a unit vector
        norm = torch.norm(out, dim=-1, keepdim=True)
        return out / (norm + 1e-8)

class RLAgent:
    def __init__(self, input_size, output_size):
        self.model = DQN(input_size, output_size)
        self.optimizer = optim.Adam(self.model.parameters(), lr=0.001)
        self.criterion = nn.MSELoss()
        self.memory = []
        self.gamma = 0.99
        self.epsilon = 1.0  # You can use this to add exploration noise.
        self.epsilon_decay = 0.995
        self.epsilon_min = 0.1
        self.batch_size = 16
        self.writer = SummaryWriter(log_dir="logs")
    
    def remember(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))
        if len(self.memory) > 10000:
            self.memory.pop(0)
    
    def act(self, state):
        # For continuous actions, we add noise for exploration
        with torch.no_grad():
            state_tensor = torch.FloatTensor(state)
            action = self.model(state_tensor)
            noise = torch.randn_like(action) * self.epsilon
            action = action + noise
            norm = torch.norm(action, dim=-1, keepdim=True)
            action = action / (norm + 1e-8)
            return action.numpy().tolist()  # Returns a list of two floats
    
    def replay(self, batch_size=None):
        if batch_size is None:
            batch_size = self.batch_size
        if len(self.memory) < batch_size:
            return None
        
        batch = random.sample(self.memory, batch_size)
        total_loss = 0
        # print("Batch:", batch)
        for state, action, reward, next_state, done in batch:
            state_tensor = torch.FloatTensor(state)
            # Our target here is the ground-truth continuous action (direction)
            target = torch.FloatTensor(action)
            output = self.model(state_tensor)
            loss = self.criterion(output, target)
            total_loss += loss.item()
            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()
        self.epsilon = max(self.epsilon_min, self.epsilon * self.epsilon_decay)
        return total_loss / batch_size
    
    def track_progress(self, reward, loss, episode):
        self.writer.add_scalar('Reward/Episode', reward, episode)
        if loss is not None:
            self.writer.add_scalar('Loss/Episode', loss, episode)
