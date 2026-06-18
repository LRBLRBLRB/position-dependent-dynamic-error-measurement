% Savitzky-Golay filter with genetic algorithm for optimize the parameters, to
%   smooth the velocity and acceleration signals processed by the IDS sensor
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
DOWN_SAMPLE_RATE = 10;
t = idsData.Time(1:DOWN_SAMPLE_RATE:end);
displacement = idsData.Displacement(1:DOWN_SAMPLE_RATE:end);

% Ensure that t & z are column vectors
t = t(:);
displacement = displacement(:);

TIME_INTERVAL = mean(diff(t)); % time interval for sampling
Fs = 1 / TIME_INTERVAL; % sampling rate
DISP_QUANT_LEVEL = 1e-4; % displacement resolution of the sensor
velo = 60 * diff(displacement) / TIME_INTERVAL;

%% pre-process
% variance of quantization noise
varQuant = (DISP_QUANT_LEVEL^2) / 12;

% 估计测量位移的噪声方差（通过实验或传感器指标）
% 如果无法准确估计，可以先假设与量化噪声方差相同，或根据实际情况设定
dispDiff = diff(displacement(1:round(Fs):end));
dispNoiseInd = find(abs(dispDiff) > 1,1);
dispNoise = displacement(1:round(Fs) * (dispNoiseInd - 1)); % 开始测量但未开始运动部分
varMeasureDisp = var(dispNoise);

% variance of velocity noise
varCalVelo = 2 * varQuant / TIME_INTERVAL^2;

% 计算平滑性权重参数 lambda
lambda = varMeasureDisp / varCalVelo;

%% 最优化寻找速度滤波参数
% 设置优化算法参数
options = optimoptions('ga', 'UseParallel', true, ...
    'PopulationSize', 20, ...
    'FunctionTolerance', 1e-2, 'MaxStallGenerations',20, ...
    'Display', 'iter', 'PlotFcn', {@gaplotdistance,@gaplotbestf});

% maximum frame length calculation according to the system memory
[userView, ~] = memory;
availableMemory = userView.MaxPossibleArrayBytes;
usableMemory = availableMemory * 0.8;
dataInfo = whos('displacement');
dataSize = dataInfo.bytes / numel(displacement);
framLenMax = sqrt(usableMemory / dataSize);

% 设置多项式阶数、窗宽的上下限。其中窗宽为保证为奇数，实际的窗宽取值为2*x2+1
lb = [2, (11 - 1) / 2];
ub = [9, (floor(framLenMax) - 1) / 2];

% genetic algorithm to seek the best parameters of 
[optimalParams, fval, exitFlag, optimalOutput] = ga( ...
    @(params) sg_filter_obj(params, displacement, TIME_INTERVAL, Fs, varMeasureDisp, ...
    varCalVelo, lambda), 2, [], [], [], [], lb, ub, [], [1, 2], options);
polyOrderOpt = round(optimalParams(1));
frameLenOpt = round(optimalParams(2));
fprintf('最优多项式阶数：%i\n最优的窗宽：%d\n', polyOrderOpt, frameLenOpt);
fprintf('最优目标函数值：%d\n迭代结束原因：%i\n', fval, exitFlag);

% polyOrderOpt = 7;
% frameLenOpt = floor(framLenMax);
[dispSG, veloSG] = sg_filter(displacement, polyOrderOpt, frameLenOpt, TIME_INTERVAL);

%% 绘制结果
figure;
plot(t, displacement, 'LineWidth', 1);
hold on;
plot(t, dispSG, 'LineWidth', 1);
xlabel('时间 (s)');
ylabel('位移');
legend('原始位移','滤波位移');
title('位移数据');

figure;
plot(t(2:end), velo, 'LineWidth', 0.5);
hold on;
plot(t(2:end), veloSG, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('速度');
legend('原始速度','滤波速度');
title('速度估计（使用 S-G 滤波器）');

figure;
plot(t(3:end), diff(veloSG) / TIME_INTERVAL / 60000, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('加速度');
title('加速度估计（使用 S-G 滤波器）');

%%
function [dispSG, veloSG] = sg_filter(data, polyOrder, frameLen, dt)
    % SG滤波器：多项式阶数polyOrder，窗宽frameLen，半窗宽间隔【加权向量中使用】
    % 多项式阶数polyOrder必须大于1
    % 窗宽frameLen必须为奇数，且大于2*polyOrder+1

    % 计算窗口长度（确保为奇数）
    if mod(frameLen, 2)
        frameLen = max(frameLen, 2 * polyOrder + 1);
    else
        frameLen = 2 * polyOrder + 1;
    end

    % % weighting vector optimization
    % nhW = round((0.509+0.1922*m-0.001485*m^2)/(F3dB/Fs)-1);
    % flW = 2*nhW+1;
    % Tn = toeplitz([2 -1 zeros(1,flW-2)]);
    % v = ones(flW,1);
    % weightsOptimal = Tn\v;

    % 对位移数据进行 Savitzky-Golay 滤波（平滑位移）
    dispSG = sgolayfilt(data, polyOrder, frameLen);
    veloSG = 60*diff(dispSG) / dt;
end

function cost = sg_filter_obj(params, z, dt, fs, varMeasureDisp, varCalVelo, lambda)
    % 提取并取整多项式阶数
    polyOrder = round(params(1));
    frameLen = 2 * round(params(2)) + 1;

    % 应用 S-G 滤波器
    [dispSG,veloSG] = sg_filter(z, polyOrder, frameLen, dt);

    % 计算位移残差并标准化
    dispResidual = dispSG - z;
    dispErrorMse = mean((dispResidual.^2) / varMeasureDisp);

    % 对速度估计值进行傅里叶变换
    N = length(veloSG);
    V = fft(veloSG);
    freq = (0:N-1)' * (fs / N);

    % 设定高频阈值 f_c（根据实际情况设定）
    f_c = fs / 4; % 例如，取奈奎斯特频率的一半

    % 找到高频分量的索引
    highFreqIndices = freq > f_c;

    % 计算高频成分的能量并标准化
    smoothness = sum(abs(V(highFreqIndices)).^2) / (N * varCalVelo);

    % 计算总的代价函数
    cost = dispErrorMse + lambda * smoothness;
end
