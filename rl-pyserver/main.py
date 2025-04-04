import socket
import json
from rl_agent import RLAgent

HOST = '127.0.0.1'
PORT = 4002

agent = RLAgent(input_size=26, output_size=4)  # 121 for 11x11 tiles + 1 for is_falling

def flatten_state(state_dict):
    # Flatten state (is_falling + 11x11 tiles)
    flat = [int(state_dict.get("is_falling", 0))]
    flat += [tile for row in state_dict.get("nearby_tiles", []) for tile in row]
    return flat

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen(1)
    print("Waiting for connection...")
    while True:
        conn, addr = s.accept()
        print("Connected by", addr)
        with conn:
            buffer = b""
            episode = 0
            prev_state = None
            prev_action_idx = None
            while True:
                chunk = conn.recv(1024)
                if not chunk:
                    print("Connection closed by client.")
                    break
                
                buffer += chunk
                
                while b"\n" in buffer:
                    line, buffer = buffer.split(b"\n", 1)
                    try:
                        state = json.loads(line.decode('utf-8'))
                        print("✅ Got state:", state)

                        # Game reset or end of game (done)
                        if state.get("reset"):
                            reward = state.get("score", 0.0)  # Get score-based reward
                            agent.remember(prev_state, prev_action_idx, -10, state_vec, True)
                            loss = agent.replay()  # Learn from the experience buffer
                            pisode = episode + 1
                            agent.track_progress(-10, loss, episode=state.get("episode", 0))  # Track progress for each episode
                            prev_state = None
                        else:
                            state_vec = flatten_state(state)
                            action_idx = agent.act(state_vec)  # Select action using current policy

                            actions = [
                                {"move_left": True, "move_right": False, "jump": False, "attack": False},
                                {"move_left": False, "move_right": True, "jump": False, "attack": False},
                                {"move_left": False, "move_right": False, "jump": True, "attack": False},
                                {"move_left": False, "move_right": True, "jump": True, "attack": False},
                            ]

                            action = actions[action_idx]
                            conn.sendall((json.dumps(action) + "\n").encode("utf-8"))

                            if prev_state is not None:
                                # Calculate reward based on the game state (e.g., progress or failure)
                                reward = state.get("reward", 0.0)
                                agent.remember(prev_state, prev_action_idx, 1, state_vec, False)
                                loss = agent.replay()  # Learn from the stored experiences
                                episode = episode + 1
                                agent.track_progress(1, loss, episode=episode)  # Track progress for each episode

                            prev_state = state_vec
                            prev_action_idx = action_idx

                    except json.JSONDecodeError as e:
                        print("❌ JSON decode error:", e)

            
