% Spline curve fitting with genetic algorithm for optimize the parameters, to
%   smooth the velocity and acceleration signals processed by the IDS sensor
close all; clear; clc;
cd(fileparts(mfilename('fullpath')));

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

% downsampling
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

%% 滑动平均滤波

% 定义移动平均滤波器窗口大小的范围
minWindowSize = 3;     % 最小窗口大小
maxWindowSize = 51;    % 最大窗口大小（需为奇数）
stepSize = 2;          % 窗口大小的步长
windowSizes = minWindowSize:stepSize:maxWindowSize;

% 初始化变量
bestMetric = Inf;      % 最优评价指标初始化为正无穷大
bestWindowSize = minWindowSize;
metrics = zeros(length(windowSizes), 1);  % 存储每个窗口大小的评价指标

% 遍历每个窗口大小
for i = 1:length(windowSizes)
    windowSize = windowSizes(i);

    % 创建移动平均滤波器系数
    b = (1 / windowSize) * ones(1, windowSize);
    a = 1;

    % 对数据进行滤波
    moveData = filter(b, a, idsData.Displacement);

    % 计算评价指标：一阶差分的标准差
    diffData = diff(moveData);
    metric = std(diffData);
    metrics(i) = metric;

    % 判断是否为当前最佳参数
    if metric < bestMetric
        bestMetric = metric;
        bestWindowSize = windowSize;
        dispSpline = moveData;
    end
end
% 画图
figure;
plot(windowSizes, metrics, 'b-o');
xlabel('窗口大小');
ylabel('评价指标（差分标准差）');
title('评价指标随窗口大小的变化');
fprintf('最佳窗口大小为 %d，对应的评价指标为 %.4f。\n', bestWindowSize, bestMetric);

veloSpline = 60 * diff(dispSpline)./ diff(t);

%% 滤波结果画图
figure;
plot(t, displacement);
hold on;
plot(t, dispSpline);
legend;
xlabel('样本点');
ylabel('幅值');
legend('原始位移','滤波位移');
title('原始数据与最佳滤波后数据对比');

figure;
plot(idsData.veloTime, idsData.velo, 'DisplayName', '原始数据');
hold on;
plot(t, veloSpline, 'DisplayName', '滤波后数据');
% ylim([min(veloFilter), max(veloFilter)]);
xlabel('Time (s)');
ylabel('Velocity (mm/min)');
legend('原始速度','滤波速度');
title('速度估计（使用样条拟合）');

figure;
plot(t(3:end), diff(veloSpline) / TIME_INTERVAL / 60000, 'LineWidth', 0.5);
xlabel('时间 (s)');
ylabel('加速度');
title('加速度估计（使用样条拟合）');

%%
rmpath(genpath('../..'));
rmpath(genpath('test_quantization'));