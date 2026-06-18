% Wavelet denoise
clear; clc;
cd(fileparts(mfilename('fullpath'))); close all;
addpath(genpath('../..'));
addpath(genpath('test_quantization'));

% set(groot, 'DefaultAxesFontName', 'Times New Roman', 'DefaultAxesFontSize', 12);
% set(groot, 'DefaultTextFontName', 'Times New Roman', 'DefaultTextFontSize', 12);

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
DOWN_SAMPLE_RATE = 1;
t = idsData.Time(1:DOWN_SAMPLE_RATE:end);
disp = idsData.Displacement(1:DOWN_SAMPLE_RATE:end);

% Ensure that t & z are column vectors
t = t(:);
disp = disp(:);

TIME_INTERVAL = mean(diff(t)); % time interval for sampling
Fs = 1 / TIME_INTERVAL; % sampling rate
DISP_QUANT_LEVEL = 1e-4; % displacement resolution of the sensor
velo = 60 * diff(disp) / TIME_INTERVAL;

%% 小波去噪
% 位移滤波
waveName = 'sym9'; % 小波基
numLevel = min(21, wmaxlev(length(disp),waveName)); % 分解层数，越高越平滑
dispWavelet = wdenoise(disp,numLevel, ...
    Wavelet=waveName, ...
    DenoisingMethod='Bayes', ...
    ThresholdRule='Soft', ...
    NoiseEstimate='LevelIndependent');

% [wt, levels] = wavedec(disp, levels, waveName); % 小波分解
% sigma = wnoisest(wt, numLevel); % 阈值方法
% threshold = wbmpen(wt, numLevel, sigma, 6);
% dispWavelet2 = wdencmp('gbl', wt, numLevel, waveName, threshold, 's'); % 去噪

% 计算平滑后的位移和速度
veloWavelet = 60 * diff(dispWavelet) ./ diff(t);

sp = spaps(t(2:end), veloWavelet, 10000000, [], 2);
veloWaveletSpaps = fnval(sp, t(2:end));

%% 绘制结果
figure;
plot(t, disp, 'LineWidth', 1);
hold on;
plot(t, dispWavelet, 'LineWidth', 1);
xlabel('时间 (s)');
ylabel('位移');
legend('原始位移','滤波位移');
title('位移数据');

figure;
plot(t(2:end), velo, 'LineWidth', 0.5);
hold on;
plot(t(2:end), veloWavelet, 'LineWidth', 0.5);
plot(t(2:end), veloWaveletSpaps, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('速度');
legend('原始速度','滤波速度');
title('速度估计（使用样条拟合）');

figure;
plot(t(3:end), diff(veloWaveletSpaps) / TIME_INTERVAL / 60000, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('加速度');
title('加速度估计（使用样条拟合）')