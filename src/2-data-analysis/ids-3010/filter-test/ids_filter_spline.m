clear; clc;
cd(fileparts(mfilename('fullpath'))); close all;

filePath = "D:\WorkingDir\Experiments\202406-mms-dynamics\ids results mat\20240530 IDS\XD_Y0_A3J80.mat";
idsData = load(filePath);
idsData = struct2table(idsData); 

% 为啥ids的Y轴位移数据都是负的？记得统一一下方向！
diffTime = idsData.Time(2) - idsData.Time(1);
sampleRate = 1 / diffTime;

fig1 = figure('Name', '【IDS】原始图像');
subplot(2, 1, 1);
plot(idsData.Time, idsData.Displacement);
xlabel('Time (s)');
ylabel('Displacement (mm)');

% 原始速度计算
idsData.veloTime = 0.5 * (idsData.Time(1:end - 1) + idsData.Time(2:end));
idsData.velo = 60 * diff(idsData.Displacement)./ diff(idsData.Time);

% 画速度原始图像
subplot(2, 1, 2);
plot(idsData.veloTime, idsData.velo, 'LineWidth', 1);
ylim([min(idsData.velo), max(idsData.velo)]);
xlabel('Time (s)');
ylabel('Velocity (mm/min)');


%% downsampling
DOWNSAMPLE_RATE = 50;
t = idsData.Time(1:DOWNSAMPLE_RATE:end);
disp = idsData.Displacement(1:DOWNSAMPLE_RATE:end);
clear idsData;

% Ensure that t & z are column vectors
t = (t(:));
disp = (disp(:));

TIME_INTERVAL = mean(diff(t,1,1)); % time interval for sampling
Fs = 1 / TIME_INTERVAL; % sampling rate
DISP_QUANT_LEVEL = 1e-4; % displacement resolution of the sensor
velo = 60 * diff(disp,1,1) / TIME_INTERVAL;

%% 平滑样条拟合
% 使用 csaps 函数自动选择最佳平滑参数
% [sp, p_optimal] = csaps(t, disp, []);
[sp, fval] = spaps(t, disp, 1, [], 3);


% 计算平滑后的位移和速度
dispSpline = fnval(sp, t);
veloSpline = 60 * fnval(fnder(sp, 1), t);





%% 绘制结果
figure;
plot(t, disp, 'LineWidth', 1);
hold on;
plot(t, dispSpline, 'LineWidth', 1);
xlabel('时间 (s)');
ylabel('位移');
legend('原始位移','滤波位移');
title('位移数据');

figure;
plot(t(2:end), velo, 'LineWidth', 0.5);
hold on;
plot(t, veloSpline, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('速度');
legend('原始速度','滤波速度');
title('速度估计（使用样条拟合）');

figure;
plot(t(2:end), diff(veloSpline) / TIME_INTERVAL / 60000, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('加速度');
title('加速度估计（使用样条拟合）');