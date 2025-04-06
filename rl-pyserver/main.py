import socket
import json
from rl_agent import RLAgent
import torch
import os

HOST = '127.0.0.1'
PORT = 4004

def load_checkpoint(agent, filename="checkpoint.pth"):
    if os.path.exists(filename):
        checkpoint = torch.load(filename, weights_only=False)
        agent.model.load_state_dict(checkpoint['model_state_dict'])
        agent.optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        agent.epsilon = checkpoint['epsilon']
        agent.memory = checkpoint['memory']
        episode = checkpoint.get('episode', 0)
        print(f"Checkpoint loaded from {filename}, resuming at episode {episode}")
        return episode
    else:
        print("No checkpoint found, starting fresh.")
        return 0

def save_checkpoint(agent, episode, filename="checkpoint.pth"):
    checkpoint = {
        'model_state_dict': agent.model.state_dict(),
        'optimizer_state_dict': agent.optimizer.state_dict(),
        'epsilon': agent.epsilon,
        'episode': episode,
        'memory': agent.memory
    }
    torch.save(checkpoint, filename)
    print(f"Checkpoint saved to {filename}")

def flatten_state(state_dict):
    # State consists of:
    # "projectile_direction": [dir_x, dir_y]
    # "player_position": [player_x, player_y]
    # "enemy_position": [enemy_x, enemy_y]
    flat = []
    flat += state_dict.get("projectile_direction", [0, 0])
    print(flat)
    # flat += state_dict.get("player_position", [0, 0])
    # flat += state_dict.get("enemy_position", [0, 0])
    print(flat)
    return flat

# Instantiate the agent with 6 inputs and 2 continuous outputs (direction vector)
agent = RLAgent(input_size=2, output_size=2)
episode = load_checkpoint(agent, filename="checkpoint.pth")

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen(1)
    print("Waiting for connection...")
    while True:
        conn, addr = s.accept()
        print("Connected by", addr)
        with conn:
            buffer = b""
            prev_state = None
            prev_target = None  # ground-truth direction (for training)
            try:
                while True:
                    chunk = conn.recv(1024)
                    if not chunk:
                        print("Connection closed by client.")
                        save_checkpoint(agent, episode)
                        break
                    
                    buffer += chunk
                    
                    while b"\n" in buffer:
                        line, buffer = buffer.split(b"\n", 1)
                        try:
                            state = json.loads(line.decode('utf-8'))
                            print("✅ Got state:", state)
                            
                            if state.get("reset"):
                                reward = state.get("score", 0.0)
                                # # End of episode update: use last transition with negative reward if desired
                                # if prev_state is not None:
                                #     agent.remember(prev_state, prev_target, -10, flatten_state(state), True)
                                #     loss = agent.replay()
                                #     episode += 1
                                #     agent.track_progress(-10, loss, episode)
                                # prev_state = None
                            else:
                                state_vec = flatten_state(state)
                                # Ground truth direction is provided in the state
                                target_direction = state.get("projectile_direction", [0, 0])
                                # Agent predicts a direction vector
                                predicted_direction = agent.act(state_vec)
                                
                                # Send predicted direction to Godot
                                action_dict = {"projectile_direction": predicted_direction}
                                print(action_dict)
                                conn.sendall((json.dumps(action_dict) + "\n").encode("utf-8"))

                                prev_state = state_vec
                                prev_target = target_direction
                                
                                if prev_state is not None:
                                    # Here we use a reward from the game, for example 1 for a "good" shot.
                                    # check if predicted direction is close to the target direction
                                    print("Predicted direction:", predicted_direction)
                                    print("Target direction:", target_direction)
                                    import numpy as np

                                    # Normalize
                                    predicted_norm = predicted_direction / np.linalg.norm(predicted_direction)
                                    target_norm = target_direction / np.linalg.norm(target_direction)

                                    # Dot and cross product
                                    dot = np.dot(predicted_norm, target_norm)
                                    cross = np.cross(predicted_norm, target_norm)  # Scalar in 2D

                                    # Clip for safety
                                    dot = np.clip(dot, -1.0, 1.0)

                                    # Signed angle
                                    angle_rad = np.arctan2(cross, dot)
                                    angle_deg = np.degrees(angle_rad)

                                    print(f"Signed angle in degrees: {angle_deg}")

                                    reward = (2 ** ((180-abs(angle_deg))/18)) / 100

                                    print("Reward:", reward)

                                    agent.remember(prev_state, prev_target, reward, state_vec, False)
                                    loss = agent.replay()
                                    episode += 1
                                    agent.track_progress(reward, loss, episode)
                                
                                prev_state = state_vec
                                prev_target = target_direction  # use the ground-truth direction as target
                        except json.JSONDecodeError as e:
                            print("❌ JSON decode error:", e)
            except Exception as e:
                print("Unexpected error:", e)
                save_checkpoint(agent, episode)
