% 读取文件内容
fileContent = fileread("D:\Research\experiments\ADXL results\20240806 ADXL\Z_A2J40.csv");

% 正则表达式提取包含acc的行，并提取时间和三个数据
pattern = '(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+), acc:#(-?\d+\.\d+)#(-?\d+\.\d+)#(-?\d+\.\d+)';
matches = regexp(fileContent, pattern, 'tokens');

% 初始化数据结构
timestamps = datetime.empty; %datetime([], 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
acc_x = [];
acc_y = [];
acc_z = [];

% 提取数据
for i = 1:length(matches)
    timestamps(end+1) = datetime(matches{i}{1}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
    acc_x(end+1) = str2double(matches{i}{2});
    acc_y(end+1) = str2double(matches{i}{3});
    acc_z(end+1) = str2double(matches{i}{4})/2;
end

% 绘制图表
figure;
tmp = get(gcf,'Position');
set(gcf,'Position',[tmp(1:3),tmp(4)/2]);
% subplot(3, 1, 1);
% plot(timestamps, acc_x, 'r');
% xlabel('Time');
% ylabel('Acc X');
% title('Acc X over Time');
% grid on;
% 
% subplot(3, 1, 2);
% plot(timestamps, acc_y, 'g');
% xlabel('Time');
% ylabel('Acc Y');
% title('Acc Y over Time');
% grid on;

% subplot(3, 1, 3);
plot(timestamps, acc_z);
xlabel('时间');
ylabel('Z轴加速度 (g)');
title('A2 J40 Z轴加速度曲线');
grid on;

% 调整布局，使图表更加紧凑
% tight_layout();
