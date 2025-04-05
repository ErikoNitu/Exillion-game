import socket
import json
from rl_agent import RLAgent
import torch
import os

HOST = '127.0.0.1'
PORT = 4002

def load_checkpoint(agent, filename="checkpoint.pth"):
    if os.path.exists(filename):
        checkpoint = torch.load(filename)
        agent.model.load_state_dict(checkpoint['model_state_dict'])
        agent.target_model.load_state_dict(checkpoint['target_model_state_dict'])
        agent.optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        agent.epsilon = checkpoint['epsilon']
        agent.memory = checkpoint['memory']
        episode = checkpoint.get('episode', 0)
        print(f"Checkpoint loaded from {filename}, resuming at episode {episode}")
        return episode
    else:
        print("No checkpoint found, starting fresh.")
        return None

agent = RLAgent(input_size=26, output_size=4)  # 121 for 11x11 tiles + 1 for is_falling

def flatten_state(state_dict):
    # Flatten state (is_falling + 11x11 tiles)
    flat = [int(state_dict.get("is_falling", 0))]
    flat += [tile for row in state_dict.get("nearby_tiles", []) for tile in row]
    return flat

def save_checkpoint(agent, episode, filename="checkpoint.pth"):
    checkpoint = {
        'model_state_dict': agent.model.state_dict(),
        'target_model_state_dict': agent.target_model.state_dict(),
        'optimizer_state_dict': agent.optimizer.state_dict(),
        'epsilon': agent.epsilon,
        'episode': episode,
        'memory': agent.memory
    }
    torch.save(checkpoint, filename)
    print(f"Checkpoint saved to {filename}")

# ... inside your while True loop, when you detect a disconnect:
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen(1)
    print("Waiting for connection...")
    while True:
        conn, addr = s.accept()
        print("Connected by", addr)
        with conn:
            buffer = b""
            episode = load_checkpoint(agent, filename="checkpoint.pth")
            prev_state = None
            prev_action_idx = None
            try:
                while True:
                    chunk = conn.recv(1024)
                    if not chunk:
                        print("Connection closed by client.")
                        # Save progress before breaking out of the loop
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
                                agent.remember(prev_state, prev_action_idx, -10, state_vec, True)
                                loss = agent.replay()
                                episode += 1
                                agent.track_progress(-10, loss, episode=state.get("episode", 0))
                                prev_state = None
                            else:
                                state_vec = flatten_state(state)
                                action_idx = agent.act(state_vec)
                                
                                actions = [
                                    {"move_left": True, "move_right": False, "jump": False, "attack": False},
                                    {"move_left": False, "move_right": True, "jump": False, "attack": False},
                                    {"move_left": False, "move_right": False, "jump": True, "attack": False},
                                    {"move_left": False, "move_right": True, "jump": True, "attack": False},
                                ]
                                
                                action = actions[action_idx]
                                conn.sendall((json.dumps(action) + "\n").encode("utf-8"))
                                
                                if prev_state is not None:
                                    reward = state.get("reward", 0.0)
                                    agent.remember(prev_state, prev_action_idx, 1, state_vec, False)
                                    loss = agent.replay()
                                    episode += 1
                                    agent.track_progress(1, loss, episode=episode)
                                
                                prev_state = state_vec
                                prev_action_idx = action_idx
                        except json.JSONDecodeError as e:
                            print("❌ JSON decode error:", e)
            except Exception as e:
                print("Unexpected error:", e)
                # Optionally save checkpoint here as well
                save_checkpoint(agent, episode)
