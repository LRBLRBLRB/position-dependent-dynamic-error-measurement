import numpy as np
trials = 1000000
D = 5000  # mm
u_noise = 0.1
u_pos = 0.1
u_servo = 0.1 / np.sqrt(3)
sys_bias = 0.19 * D / 1000  # µm
u_sys = sys_bias / np.sqrt(3)
u_fixture = 0.1 / np.sqrt(3)
noise = np.random.normal(0, u_noise, trials)
pos = np.random.normal(0, u_pos, trials)
servo = np.random.uniform(-u_servo*np.sqrt(3), u_servo*np.sqrt(3), trials)
sys_err = np.random.uniform(-u_sys*np.sqrt(3), u_sys*np.sqrt(3), trials)
fixture = np.random.uniform(-u_fixture*np.sqrt(3), u_fixture*np.sqrt(3), trials)
delta_L = noise + pos + servo + sys_err + fixture
u_c = np.std(delta_L)
U = 2 * u_c  # Approx for normal
print(U)