% close all;
% clear; clc;
addpath(genpath('..'));

set(groot, 'DefaultAxesFontName', 'Times New Roman', 'DefaultAxesFontSize', 12);
set(groot, 'DefaultTextFontName', 'Times New Roman', 'DefaultTextFontSize', 12);
set(groot, 'DefaultAxesXMinorTick', 'on');

GEOMETRIC_ERROR_MAP = "../X_positioning_error.mat";

FILE_PATH = "D:\WorkingDir\Experiments\202406-mms-dynamics\Siemens results mat\20240601 Siemens\XB_Y1500_A3J80.mat";
[~,fileName,~] = fileparts(FILE_PATH);
theoAccelPattern = 'A(\d+)'; % 匹配"A"后面的数字
match = regexp(fileName, theoAccelPattern, 'tokens');
THEORETICAL_ACCEL = str2double(match{1}{1});
clear theoAccelPattern match;

load(FILE_PATH, "siemensTable");
siemensData.time = reshape(siemensTable.time, [], 1);
siemensData.disp1 = reshape(siemensTable.disp1, [], 1);
siemensData.disp2 = reshape(siemensTable.disp2, [], 1);
siemensData.int1 = reshape(siemensTable.int1, [], 1);
siemensData.int2 = reshape(siemensTable.int2, [], 1);
% siemensData = struct("time", num2cell(siemensTable.time), ...
%     "disp1", num2cell(siemensTable.disp1), ...
%     "disp2", num2cell(siemensTable.disp2), ...
%     "int1", num2cell(siemensTable.int1), ...
%     "int2", num2cell(siemensTable.int2));
% siemensData = arrayfun(@(t, x1, x2, y1, y2) struct('time', t, 'disp1', x1, 'disp2', x2, 'int1', y1, 'int2', y2), ...
%     siemensTable.time, siemensTable.disp1, siemensTable.disp2, siemensTable.int1, siemensTable.int2);
clear siemensTable;

% 位移数据，开始方向确认
% *******************************************************************************
% ************* 不同测点的情况会有不同，在换测点时必须留意此处！！！！！ *************
% ************* 但是，理论上光栅尺的数据是标准的，不需要这一步。        *************
% *******************************************************************************

% siemensData.disp1 = siemensData.disp1 - 1000 + siemensData.disp1(1);
% siemensData.disp2 = siemensData.disp2 - 1000 + siemensData.disp2(1);

% fig1 = figure('Name', '【光栅尺】位移原始图像');
% ax1 = subplot(3, 1, 1);
% plot(siemensData.time, siemensData.disp1, 'Color', [0 0.4470 0.7410]);
% ylabel('Disp1 (mm)');
% ax2 = subplot(3, 1, 2);
% plot(siemensData.time, siemensData.disp2, 'Color', [0.8500 0.3250 0.0980]);
% ylabel('Disp2 (mm)');
% ax3 = subplot(3, 1, 3);
% plot(siemensData.time, siemensData.disp2 - siemensData.disp1, 'Color', [0.4940 0.1840 0.5560]);
% ylabel('\DeltaDisp (mm)');
% linkaxes([ax1, ax2, ax3], 'x');
% xlabel('Time (s)');

%% ----------------- 位移数据处理：滤波与抽样 -----------------
% % Data low-pass filtering for denoising
% WAVE_NAME = 'sym9'; % 小波基
% NUM_LEVEL = min(21, wmaxlev(length(siemensData.disp1),WAVE_NAME)); % 分解层数，越高越平滑
% dispWavelet1 = wdenoise(siemensData.disp1,NUM_LEVEL, ...
%     Wavelet=WAVE_NAME, ...
%     DenoisingMethod='Bayes', ...
%     ThresholdRule='Soft', ...
%     NoiseEstimate='LevelIndependent');
% dispWavelet2 = wdenoise(siemensData.disp2,NUM_LEVEL, ...
%     Wavelet=WAVE_NAME, ...
%     DenoisingMethod='Bayes', ...
%     ThresholdRule='Soft', ...
%     NoiseEstimate='LevelIndependent');
% 
% % dispWavelet1 = siemensData.disp1;
% % dispWavelet2 = siemensData.disp2;
% 
% % Data downsampling
% DOWN_SAMPLE_RATE = 1;
% tmpTime = siemensData.time(1:DOWN_SAMPLE_RATE:end);
% tmpDisp1 = dispWavelet1(1:DOWN_SAMPLE_RATE:end);
% tmpDisp2 = dispWavelet2(1:DOWN_SAMPLE_RATE:end);
% 
% % figure;
% % plot(siemensData.time, siemensData.disp1);
% % hold on;
% % plot(siemensData.time, dispWavelet1);
% % plot(tmpTime, tmpDisp1);

TIME_INTERVAL = siemensData.time(2) - siemensData.time(1);
SAMPLE_RATE = 1 / TIME_INTERVAL;

% % 计算滤波后的速度
% siemensData.veloTime = 0.5 * (tmpTime(1:end - 1) + tmpTime(2:end));
% siemensData.velo1 = 60 * diff(tmpDisp1)./diff(tmpTime);
% siemensData.velo2 = 60 * diff(tmpDisp2)./diff(tmpTime);
% 
% % 画位置和速度的滤波图像
% fig1 = figure('name', '【光栅尺1】位移滤波效果');
% subplot(2, 1, 1);
% plot(siemensData.time, siemensData.disp1, 'DisplayName', 'Original');
% hold on;
% plot(tmpTime, tmpDisp1, 'DisplayName', 'Filtered');
% legend;
% ylabel('Displacement (mm)');
% subplot(2, 1, 2);
% plot(0.5 * (siemensData.time(1:end - 1) + siemensData.time(2:end)), ...
%     60 * diff(siemensData.disp1) ./ diff(siemensData.time), ...
%     'LineWidth', 1, 'DisplayName', 'Original');
% hold on;
% plot(siemensData.veloTime, siemensData.velo1, 'LineWidth', 1, 'DisplayName', 'Filtered');
% legend;
% % ylim([min(idsData.velo), max(idsData.velo)]);
% xlabel('Time (s)');
% ylabel('Velocity (mm/min)');
% 
% fig2 = figure('name', '【光栅尺2】位移滤波效果');
% subplot(2, 1, 1);
% plot(siemensData.time, siemensData.disp2, 'DisplayName', 'Original');
% hold on;
% plot(tmpTime, tmpDisp2, 'DisplayName', 'Filtered');
% legend;
% ylabel('Displacement (mm)');
% subplot(2, 1, 2);
% plot(0.5 * (siemensData.time(1:end - 1) + siemensData.time(2:end)), ...
%     60 * diff(siemensData.disp2) ./ diff(siemensData.time), ...
%     'LineWidth', 1, 'DisplayName', 'Original');
% hold on;
% plot(siemensData.veloTime, siemensData.velo2, 'LineWidth', 1, 'DisplayName', 'Filtered');
% legend;
% % ylim([min(idsData.velo), max(idsData.velo)]);
% xlabel('Time (s)');
% ylabel('Velocity (mm/min)');
% 
% % 存储滤波后的位移结果（滤波后的速度结果已于上面存储）
% siemensData.time = tmpTime;
% siemensData.disp1 = tmpDisp1;
% siemensData.disp2 = tmpDisp2;
% clear tmpTime tmpDisp1 dispWavelet1 tmpDisp2 dispWavelet2;

% 位移数据处理：定位误差滤除
% load the geometric error fitting result
load(GEOMETRIC_ERROR_MAP);

% take the geometric error into account
geometricError1 = ppval(geometric_error_pp, siemensData.disp1);
geometricError2 = ppval(geometric_error_pp, siemensData.disp2);
tmpDisp1 = siemensData.disp1 - geometricError1;
tmpDisp2 = siemensData.disp2 - geometricError2;

% plot the geometric error
figure('Name', '【光栅尺】位移定位误差滤除');
tiledlayout(3,1);
ax1 = nexttile;
yyaxis("left");
plot(siemensData.time, siemensData.disp1);
ylabel("Disp (mm)");
title(ax1, 'Displacement measured by the encoder 1');
y_min = min(siemensData.disp1);
y_max = max(siemensData.disp1);
if y_min > 0
    ylim([0, y_max]);
elseif y_max < 0
    ylim([y_min, 0]);
else
    ylim([y_min, y_max]);
end
yyaxis("right");
area(siemensData.time, geometricError1, 0, ...
    "EdgeColor", [0.8500 0.3250 0.0980], "EdgeAlpha", 0.5, ...
    "FaceColor", [0.8500 0.3250 0.0980], "FaceAlpha", 0.1);
ylabel("Error (mm)");
legend('Original dispalcement', 'Geometric error', 'Location', 'northoutside', 'Orientation', 'horizontal');

ax2 = nexttile;
yyaxis("left");
plot(siemensData.time, siemensData.disp2);
ylabel("Disp (mm)");
title(ax2, 'Displacement measured by the encoder 2');
y_min = min(siemensData.disp2);
y_max = max(siemensData.disp2);
if y_min > 0
    ylim([0, y_max]);
elseif y_max < 0
    ylim([y_min, 0]);
else
    ylim([y_min, y_max]);
end
yyaxis("right");
area(siemensData.time, geometricError2, 0, ...
    "EdgeColor", [0.8500 0.3250 0.0980], "EdgeAlpha", 0.5, ...
    "FaceColor", [0.8500 0.3250 0.0980], "FaceAlpha", 0.1);
ylabel("Error (mm)");

ax3 = nexttile;
plot(siemensData.time, siemensData.disp2 - siemensData.disp1, 'Color', [0.4940 0.1840 0.5560]);
ylabel('\DeltaDisp (mm)');
title(ax3, 'Difference between two displacement signals');
linkaxes([ax1, ax2, ax3], 'x');
xlabel("Time (s)");

siemensData.disp1 = tmpDisp1;
siemensData.disp2 = tmpDisp2;

clear ax1 ax2 ax3 tmpDisp1 tmpDisp2;

% （无需滤波和降采样的话）计算原始速度，并画图
siemensData.veloTime = 0.5 * (siemensData.time(1:end - 1) + siemensData.time(2:end));
siemensData.velo1 = 60 * diff(siemensData.disp1)./diff(siemensData.time);
siemensData.velo2 = 60 * diff(siemensData.disp2)./diff(siemensData.time);

figure('name', '【光栅尺】速度原始图像');
tiledlayout(3, 1);
ax1 = nexttile;
plot(siemensData.veloTime, siemensData.velo1, 'Color', [0 0.4470 0.7410]);
ylabel('Velocity (mm/min)');
ax2 = nexttile;
plot(siemensData.veloTime, siemensData.velo2, 'Color', [0.8500 0.3250 0.0980]);
ylabel('Velocity (mm/min)');
ax3 = nexttile;
plot(siemensData.veloTime, siemensData.velo2 - siemensData.velo1, 'Color', [0.4940 0.1840 0.5560]);
ylabel('Velocity (mm/min)');
% ylim([min([siemensData.velo2;siemensData.velo1]), ...
%     max([siemensData.velo2;siemensData.velo1])]);
linkaxes([ax1, ax2, ax3], 'x');
xlabel('Time (s)');

%% ----------------- 速度滤波处理（为了加速度计算） -----------------
% 速度曲线滤波
% siemensData.velo1_filtered = siemensData.velo1;
% siemensData.velo2_filtered = siemensData.velo2;
% 高斯滤波，不能解决匀加减速过程，或者匀速过程抖动对加速度计算的影响。
% siemensData.velo1_filtered = filter_gaussian(100, 1, siemensData.velo1);
% siemensData.velo2_filtered = filter_gaussian(100, 1, siemensData.velo2);
% 移动平均滤波
% windowSize = 20;  % 设置滑动窗口为10个数据
% filterCoeff = (1 / windowSize) * ones(1, windowSize);
% fDelay = (length(filterCoeff)-1) / 2;
% siemensData.velo1_filtered = filter(filterCoeff, 1, siemensData.velo1);
% siemensData.velo2_filtered = filter(filterCoeff, 1, siemensData.velo2);
% 样条拟合平滑
sp = spaps(siemensData.veloTime, siemensData.velo1, 10000, [], 2);
siemensData.velo1_filtered = fnval(sp, siemensData.veloTime);
sp = spaps(siemensData.veloTime, siemensData.velo2, 10000, [], 2);
siemensData.velo2_filtered = fnval(sp, siemensData.veloTime);
clear sp;

% 计算加速度
siemensData.accelTime = 0.5 * (siemensData.veloTime(1:end - 1) + siemensData.veloTime(2:end));
siemensData.accel1 = diff(siemensData.velo1_filtered) ./ diff(siemensData.veloTime) ./ 60000;
siemensData.accel2 = diff(siemensData.velo2_filtered) ./ diff(siemensData.veloTime) ./ 60000;

% 查看速度滤波的效果 （结果就是滤波作用不大）
figure('Name','【光栅尺1】速度滤波结果');
subplot(2, 1, 1);
plot(siemensData.veloTime, siemensData.velo1, 'DisplayName', 'Original');
hold on;
plot(siemensData.veloTime, siemensData.velo1_filtered, 'DisplayName', 'Filtered');
legend;
title('Velocity curve before & after filtering');
subplot(2, 1, 2);
plot(siemensData.accelTime, diff(siemensData.velo1) ./ diff(siemensData.veloTime) ./ 60000, ...
    'DisplayName', 'Original');
hold on;
plot(siemensData.accelTime, siemensData.accel1, 'DisplayName', 'Filtered');
title('Acceleration curve before & after filtering');
legend;

figure('Name','【光栅尺2】速度滤波结果');
subplot(2, 1, 1);
plot(siemensData.veloTime, siemensData.velo2, 'DisplayName', 'Original');
hold on;
plot(siemensData.veloTime, siemensData.velo2_filtered, 'DisplayName', 'Filtered');
legend;
title('Velocity curve before & after filtering');
subplot(2, 1, 2);
plot(siemensData.accelTime, diff(siemensData.velo2) ./ diff(siemensData.veloTime) ./ 60000, ...
    'DisplayName', 'Original');
hold on;
plot(siemensData.accelTime, siemensData.accel2, 'DisplayName', 'Filtered');
title('Acceleration curve before & after filtering');
legend;

% 画加速度原始图像
% fig5 = figure('name', '【光栅尺】加速度原始图像');
% tiledlayout(3, 1);
% ax1 = nexttile;
% plot(siemensData.accelTime, siemensData.accel1, 'Color', [0 0.4470 0.7410]);
% ylabel('a (m/s^2)');
% ax2 = nexttile;
% plot(siemensData.accelTime, siemensData.accel2, 'Color', [0.8500 0.3250 0.0980]);
% ylabel('a (m/s^2)');
% ax3 = nexttile;
% plot(siemensData.accelTime, siemensData.accel2 - siemensData.accel1, 'Color', [0.4940 0.1840 0.5560]);
% ylabel('\Deltaa (m/s^2)');
% ylim([min([siemensData.accel2;siemensData.accel1]), ...
%     max([siemensData.accel2;siemensData.accel1])]);
% xlabel('Time (s)');

%% ----------------- 位移分段分析 -----------------
% 使用findpeaks函数，排除噪声并寻找所有局部最值。计算局部最值离理想值的差值，作为偏差
% 下标1和2分别代表下方光栅尺和上方光栅尺
shiftTime = ceil(0.1 * SAMPLE_RATE); % the time interval around the peak/valley value
dispPeaks1 = peak_segmentation(siemensData.time, siemensData.disp1, [], ...
    "PlotName", "【光栅尺1】位移峰谷值", "IsNormalization", false, "MinPeakProminence", 10);
dispPeaks1.dispRange(:, 1) = dispPeaks1.ind - shiftTime;
dispPeaks1.dispRange(:, 2) = dispPeaks1.ind + shiftTime + 1;
tmp = table(NaN, NaN, NaN, NaN, NaN, NaN, NaN, [NaN, NaN], 'VariableNames', dispPeaks1.Properties.VariableNames);
dispPeaks1(end + 1, :) = tmp; % more convenient to be copied into excel

dispPeaks2 = peak_segmentation(siemensData.time, siemensData.disp2, [], ...
    "PlotName", "【光栅尺2】位移峰谷值", "IsNormalization", false, "MinPeakProminence", 10);
dispPeaks2.dispRange(:, 1) = dispPeaks2.ind - shiftTime;
dispPeaks2.dispRange(:, 2) = dispPeaks2.ind + shiftTime + 1;
dispPeaks2(end + 1, :) = tmp; % same as above

%% ----------------- 速度指标计算 -----------------
% Extract velocity segments from the signal
[velocitySegment1, desiredValue1, tLim1End] = velocity_segmentation(siemensData.velo1, SAMPLE_RATE, 'case', 'Siemens');
[velocitySegment2, desiredValue2, tLim2End] = velocity_segmentation(siemensData.velo2, SAMPLE_RATE, 'case', 'Siemens');

% Draw each segments of the velocity signal
fig7 = figure('Name', '【光栅尺1】速度指标计算');
t1 = tiledlayout(fig7, 4, 3, "TileSpacing", "tight", 'Padding', 'tight');
n1 = nexttile(t1, 1, [2, 3]);
hLine = plot(siemensData.veloTime, siemensData.velo1, 'LineWidth', 0.5, 'DisplayName', 'Velocity');
hold on;
for ii = 1:length(desiredValue1)
    if ~isnan(desiredValue1(ii))
        plotObj = plot(siemensData.veloTime(velocitySegment1(ii, 1):velocitySegment1(ii, 2)), ...
            siemensData.velo1(velocitySegment1(ii, 1):velocitySegment1(ii, 2)), ...
            'LineWidth', 1.25, 'LineStyle', ':');
        plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
    end
end
scatter(siemensData.veloTime(velocitySegment1(:, 1)), siemensData.velo1(velocitySegment1(:, 1)), ...
    12, 'MarkerEdgeColor', [0.8500 0.3250 0.0980], 'MarkerFaceColor', 'flat', ...
    'DisplayName', 'Strat Location');
scatter(siemensData.veloTime(velocitySegment1(:, 2)), siemensData.velo1(velocitySegment1(:, 2)), ...
    12, 'MarkerEdgeColor', [0.9290 0.6940 0.1250], 'MarkerFaceColor', 'flat', ...
    'DisplayName', 'End Location');
legend('Location', 'best');
% title(n1, 'Segmented Velocity');
hAxes = ancestor(hLine, 'Axes');
tLim1 = [0, siemensData.veloTime(tLim1End) + 5];
plotObj = plot(tLim1, [5000, 5000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim1, [-5000, -5000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim1, [30000, 30000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim1, [-30000, -30000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
hAxes.XLim = tLim1;
ylabel('Velocity (mm/min)');

fig8 = figure('Name', '【光栅尺2】速度指标计算');
t2 = tiledlayout(fig8, 4, 3, "TileSpacing", "tight", 'Padding', 'tight');
n2 = nexttile(t2, 1, [2, 3]);
hLine = plot(siemensData.veloTime, siemensData.velo2, 'LineWidth', 0.5, 'DisplayName', 'Velocity');
hold on;
for ii = 1:length(desiredValue2)
    if ~isnan(desiredValue2(ii))
        plotObj = plot(siemensData.veloTime(velocitySegment2(ii, 1):velocitySegment2(ii, 2)), ...
            siemensData.velo2(velocitySegment2(ii, 1):velocitySegment2(ii, 2)), ...
            'LineWidth', 1.25, 'LineStyle', '--');
        plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
    end
end
scatter(siemensData.veloTime(velocitySegment2(:, 1)), siemensData.velo2(velocitySegment2(:, 1)), ...
    12, 'MarkerEdgeColor', [0.8500 0.3250 0.0980], 'MarkerFaceColor', 'flat', ...
    'DisplayName', 'Strat Location');
scatter(siemensData.veloTime(velocitySegment2(:, 2)), siemensData.velo2(velocitySegment2(:, 2)), ...
    12, 'MarkerEdgeColor', [0.9290 0.6940 0.1250], 'MarkerFaceColor', 'flat', ...
    'DisplayName', 'End Location');
legend('Location', 'best');
% title(n1, 'Segmented Velocity');
hAxes = ancestor(hLine, 'Axes');
tLim2 = [0, siemensData.veloTime(tLim1End) + 5];
plotObj = plot(tLim2, [5000, 5000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim2, [-5000, -5000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim2, [30000, 30000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim2, [-30000, -30000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
hAxes.XLim = tLim2;
ylabel('Velocity (mm/min)');

% Initialize for the velocity parameter struct, then changed into table
veloParam1 = struct("peakValue", {}, "peakError", {}, "peakMoment", {}, ...
    "steadyStateValue", {}, "steadyStateError", {}, ...
    "riseTime", {}, "noiseLevel", {}, "overshoot", {}, ...
    "oscillationFrequency", {}, "settlingTime", {});
veloParam2 = struct("peakValue", {}, "peakError", {}, "peakMoment", {}, ...
    "steadyStateValue", {}, "steadyStateError", {}, ...
    "riseTime", {}, "noiseLevel", {}, "overshoot", {}, ...
    "oscillationFrequency", {}, "settlingTime", {});

% Calculate the velocity parameters for each segments
for ii = 1:size(velocitySegment1, 1)
    % diffVelocitySegment = velocitySegment1(ii + 1) - velocitySegment1(ii);
    % if diffVelocitySegment > 1
    %     desiredValue = 5000; 
    % end
    % determine the desired value
    veloParam1(ii) = velo_param( ...
        siemensData.veloTime(velocitySegment1(ii, 1):velocitySegment1(ii, 2)), ...
        siemensData.velo1(velocitySegment1(ii, 1):velocitySegment1(ii, 2)), desiredValue1(ii));
end
% Add the item "startMoment" for each elements
for ii = 1:size(velocitySegment1, 1)
    veloParam1(ii).startMoment = siemensData.veloTime(velocitySegment1(ii, 1));
end
veloParam1 = struct2table(veloParam1);

for ii = 1:size(velocitySegment2, 1)
    veloParam2(ii) = velo_param( ...
        siemensData.veloTime(velocitySegment2(ii, 1):velocitySegment2(ii, 2)), ...
        siemensData.velo2(velocitySegment2(ii, 1):velocitySegment2(ii, 2)), desiredValue2(ii));
end
% Add the item "startMoment" for each elements
for ii = 1:size(velocitySegment2, 1)
    veloParam2(ii).startMoment = siemensData.veloTime(velocitySegment2(ii, 1));
end
veloParam2 = struct2table(veloParam2);

% 画图展示速度评价参数
nexttile(t1, 7, [1, 3]);
yyaxis left;
bar(siemensData.veloTime(velocitySegment1(:, 1)), veloParam1.peakError, 1, "LineStyle", "none");
ylabel('Peak error (mm/min)');
xlabel('Time (s)');
yyaxis right;
plot(siemensData.veloTime(velocitySegment1(:, 1)), 100 * veloParam1.overshoot, ...
    "Marker", "diamond", "MarkerSize", 4, "Color", [0.8500 0.3250 0.0980], ...
    "MarkerEdgeColor", [0.8500 0.3250 0.0980], "MarkerFaceColor", [0.8500 0.3250 0.0980]);
ylabel('Overshoot');
ytickformat('%.1g%%');
xlim(tLim1);
% legend("Peak error", "Overshoot percent", "Location", "bestoutside");
nexttile(t1, 10, [1, 1]);
yyaxis left;
plot(siemensData.veloTime(velocitySegment1(:, 1)), veloParam1.riseTime, 'o-', ...
    'MarkerSize', 3, "MarkerFaceColor", [0 0.4470 0.7410]);
hold on;
yyaxis right;
plot(siemensData.veloTime(velocitySegment1(:, 1)), veloParam1.settlingTime, 'square-', ...
    'MarkerSize', 3, "MarkerFaceColor", [0.8500 0.3250 0.0980]);
xlim(tLim1);
legend("Rising time", "Setting time", "Location", "best");
nexttile(t1, 11, [1, 1]);
plot(siemensData.veloTime(velocitySegment1(:, 1)), veloParam1.noiseLevel, ...
    "Marker", "o", "MarkerSize", 3);
xlim(tLim1);
legend("Noise level", "Location", "best");
nexttile(t1, 12, [1, 1]);
plot(siemensData.veloTime(velocitySegment1(:, 1)), veloParam1.oscillationFrequency, ...
    "Marker", "o", "MarkerSize", 3);
xlim(tLim1);
legend("Oscillation frequency", "Location", "best");

nexttile(t2, 7, [1, 3]);
yyaxis left;
bar(siemensData.veloTime(velocitySegment2(:, 1)), veloParam2.peakValue, 1, "LineStyle", "none");

ylabel('Peak error (mm/min)');
xlabel('Time (s)');
yyaxis right;
plot(siemensData.veloTime(velocitySegment2(:, 1)), 100 * veloParam2.overshoot, ...
    "Marker", "diamond", "Color", [0.8500 0.3250 0.0980], ...
    "MarkerEdgeColor", [0.8500 0.3250 0.0980], "MarkerFaceColor", [0.8500 0.3250 0.0980]);
ylabel('Overshoot');
ytickformat('%.1f%%');
xlim(tLim2);
% legend("Peak error", "Overshoot percent", "Location", "best");
nexttile(t2, 10, [1, 1]);
oo = zeros(size(veloParam2.riseTime));
yyaxis left;
b1 = bar(siemensData.veloTime(velocitySegment2(:, 1)), ...
    [veloParam2.riseTime, oo], 1, "LineStyle", "none", "FaceColor", [0 0.4470 0.7410]);
yyaxis right;
b2 = bar(siemensData.veloTime(velocitySegment2(:, 1)), ...
    [oo, veloParam2.settlingTime], 1, "LineStyle", "none", "FaceColor", [0.8500 0.3250 0.0980]);
xlim(tLim2);
legend([b1(1, 1), b2(1, 2)], {"Rising time", "Setting time"}, "Location", "best");
nexttile(t2, 11, [1, 1]);
plot(siemensData.veloTime(velocitySegment2(:, 1)), veloParam2.noiseLevel, ...
    "Marker", "o", "MarkerSize", 3);
xlim(tLim2);
legend("Noise level", "Location", "best");
nexttile(t2, 12, [1, 1]);
plot(siemensData.veloTime(velocitySegment2(:, 1)), veloParam2.oscillationFrequency, ...
    "Marker", "o", "MarkerSize", 3);
xlim(tLim2);
legend("Oscillation frequency", "Location", "best");

%% ----------------- 加速度指标计算 -----------------
% 由于加速度数据的鲁棒性远远不及位移和速度，故分段和指标计算后的数据，单独检查后再拷贝到excel文件中
[accelPeaks1,accelValleys1] = peak_segmentation(siemensData.accelTime, siemensData.accel1, ...
    THEORETICAL_ACCEL, "PlotName", "【光栅尺1】加速度峰谷值");
[accelPeaks2,accelValleys2] = peak_segmentation(siemensData.accelTime, siemensData.accel2, ...
    THEORETICAL_ACCEL, "PlotName", "【光栅尺2】加速度峰谷值");

%% ----------------- 指标整理 -----------------
% 位移、速度指标按Excel记录表格整理
paramExcel1 = save_excel(dispPeaks1, veloParam1);
paramExcel2 = save_excel(dispPeaks2, veloParam2);

% 加速度指标另外计算
num = size(paramExcel1, 1);
accelExcel1 = accel_param2excel(siemensData.accelTime, siemensData.accel1, num, ...
    accelPeaks1, accelValleys1, dispPeaks1, 'PlotName', '【光栅尺1】加速度数据最终提取结果（仿真）');
num = size(paramExcel2, 1);
accelExcel2 = accel_param2excel(siemensData.accelTime, siemensData.accel2, num, ...
    accelPeaks2, accelValleys2, dispPeaks2, 'PlotName', '【光栅尺2】加速度数据最终提取结果（仿真）');

% 合并加速度表格和位移速度表格
paramExcel1 = [paramExcel1, accelExcel1];
paramExcel2 = [paramExcel2, accelExcel2];

%% ----------------- 收尾 -----------------
[pathstr, name, ~] = fileparts(FILE_PATH);
filePath1 = fullfile(pathstr, name);
if ~isfolder(filePath1)
    mkdir(filePath1);
end
fig_save(filePath1);

% 图像平铺
fig_tiled;
fig_modal;

fprintf("The data extraction process for the file %s is completed. \n", fileName);

rmpath(genpath('..'));