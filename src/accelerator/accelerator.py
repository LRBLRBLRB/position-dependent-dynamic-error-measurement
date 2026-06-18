import socket
import threading
import time
from datetime import datetime
import re
import matplotlib.pyplot as plt
from matplotlib.dates import DateFormatter
from matplotlib.ticker import MaxNLocator

def read_and_store_tcp_data(host, port, csv_filename, stop_event):
    # 创建 TCP/IP 套接字
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    # 连接到服务器
    sock.connect((host, port))
    
    # 用于存储数据的列表
    data_list = []
    
    try:
        while not stop_event.is_set():
            # 接收数据
            data = sock.recv(16384)  # 接收最多 1024 字节
            # if not data:
            #     break  # 连接关闭，退出循环
            # 获取当前时间戳
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')
            # 假设数据是以逗号分隔的格式
            decoded_data = data.decode('utf-8').strip()
            # 将时间戳和数据一起存储
            data_list.append(f"{timestamp}, {decoded_data}")
            # time.sleep(1)  # 控制采集频率
    finally:
        # 关闭套接字
        sock.close()
    
    # 将数据写入 CSV 文件
    with open(csv_filename, 'w') as f:
        for line in data_list:
            f.write(f"{line}\n")

def stop_on_keypress(stop_event):
    input("Press Enter to stop data collection...\n")
    stop_event.set()

def data_load(data_list):
    # 存储时间和acc数据的列表
    timestamps = []
    acc_values = []

    # 解析数据
    for line in data_list.split('\n'):
        match = re.search(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+), acc:#(-?\d+\.\d+)#(-?\d+\.\d+)#(-?\d+\.\d+)', line)
        if match:
            timestamps.append(match.group(1))
            acc_values.append([float(match.group(2)), float(match.group(3)), float(match.group(4))])

    # 将acc_values转换为三个独立的列表
    acc_x = [x[0] for x in acc_values]
    acc_y = [x[1] for x in acc_values]
    acc_z = [x[2]/2 for x in acc_values] # Z需要除以2
    return timestamps, acc_x, acc_y, acc_z

# 使用示例
host = '192.168.4.1'  # 服务器的 IP 地址
port = 8080            # 服务器的端口号
# csv_filename = 'accelerator\\output.csv'  # CSV 文件名
csv_filename = 'D:\\Research\\experiments\\ADXL results\\20240806 ADXL\\XAB_Y3200_A3J80.csv'

stop_event = threading.Event()
data_thread = threading.Thread(target=read_and_store_tcp_data, args=(host, port, csv_filename, stop_event))
stop_thread = threading.Thread(target=stop_on_keypress, args=(stop_event,))

data_thread.start()
stop_thread.start()

data_thread.join()
stop_thread.join()
print("Data collection stopped and saved to CSV.")

# 读取文件内容
with open(csv_filename, 'r') as file:
    data = file.read()
timestamps, acc_x, acc_y, acc_z = data_load(data)

# 绘制图表
plt.figure(figsize=(10, 6))
plt.plot(timestamps, acc_x, label='acc_x')
plt.plot(timestamps, acc_y, label='acc_y')
plt.plot(timestamps, acc_z, label='acc_z')
plt.xlabel('Time')
plt.ylabel('Acceleration')
plt.legend()
# plt.xticks(rotation=30)
ax = plt.gca()

# 将秒的小数限制为3位
# def format_func(value, tick_number):
#     return value.strftime('%H:%M:%S.%f')[:-3]
# ax.xaxis.set_major_formatter(plt.FuncFormatter(format_func))

ax.xaxis.set_major_formatter(DateFormatter('%H:%M:%S\n.%f'))
ax.xaxis.set_major_locator(MaxNLocator(integer=True, prune='both', nbins=5))

plt.tight_layout()
plt.show()