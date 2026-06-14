% 比较ids、光栅尺和插补结果
% close all;
clear; clc;
addpath(genpath('.'));

GEOMETRIC_ERROR_MAP = '../data-analysis/X_positioning_error.mat';

%% IDS displacement
FILE_PATH = char('D:\WorkingDir\Experiments\202406-mms-dynamics\ids results mat\20240529 IDS\DYB_A3J40.mat');
[~, fileName, ~] = fileparts(FILE_PATH);
theoAccelPattern = 'A(\d+)'; % 匹配"A"后面的数字
match = regexp(fileName, theoAccelPattern, 'tokens');
theoAccel = str2double(match{1}{1});
clear theoAccelPattern match;

idsData = load(FILE_PATH);
idsData = struct2table(idsData); 

% Data low-pass filtering for denoising
WAVE_NAME = 'sym9'; % 小波基
NUM_LEVEL = min(21, wmaxlev(length(idsData.Displacement),WAVE_NAME)); % 分解层数，越高越平滑
dispWavelet = wdenoise(idsData.Displacement,NUM_LEVEL, ...
    Wavelet=WAVE_NAME, ...
    DenoisingMethod='Bayes', ...
    ThresholdRule='Soft', ...
    NoiseEstimate='LevelIndependent');
% Data downsampling
DOWN_SAMPLE_RATE = 10;
downsampleTime = idsData.Time(1:DOWN_SAMPLE_RATE:end);
downsampleDisp = dispWavelet(1:DOWN_SAMPLE_RATE:end);
% 计算滤波抽样后的时间间隔和采样率
timeTerminal = downsampleTime(2) - downsampleTime(1);
idsSampleRate = 1 / timeTerminal;
% ------------ 定位误差滤除 ------------
% load the geometric error fitting result
load(GEOMETRIC_ERROR_MAP);
% take the geometric error into account
geometricError = ppval(geometric_error_pp, downsampleDisp);
geometricRemoveDisp = downsampleDisp - geometricError;

% 存储位移数据处理结果
idsData.Time = downsampleTime;
idsData.Displacement = geometricRemoveDisp;

%% CNC displacement
FILE_PATH = "D:\WorkingDir\Experiments\202406-mms-dynamics\Siemens results mat\20240529 Siemens\DYB_A3J40.mat";
[~,fileName,~] = fileparts(FILE_PATH);
theoAccelPattern = 'A(\d+)'; % 匹配"A"后面的数字
match = regexp(fileName, theoAccelPattern, 'tokens');
THEORETICAL_ACCEL = str2double(match{1}{1});
clear theoAccelPattern match;

load(FILE_PATH, "siemensTable");
siemensData.time = reshape(siemensTable.time, [], 1);
siemensData.disp1 = -1 * reshape(siemensTable.disp1, [], 1);
siemensData.disp2 = -1 * reshape(siemensTable.disp2, [], 1);
siemensData.int1 = -1 * reshape(siemensTable.int1, [], 1);
siemensData.int2 = -1 * reshape(siemensTable.int2, [], 1);
clear siemensTable;

% 重采样：【代替下一小节的interp1】
% siemensSampleRate = 1/(siemensData.time(2) - siemensData.time(1));
% siemensInterp.time = resample(siemensData.time, idsSampleRate, siemensSampleRate);
% siemensInterp.disp1 = resample(siemensData.disp1, idsSampleRate, siemensSampleRate);
% siemensInterp.disp2 = resample(siemensData.disp2, idsSampleRate, siemensSampleRate);
% siemensInterp.int1 = resample(siemensData.int1, idsSampleRate, siemensSampleRate);
% siemensInterp.int2 = resample(siemensData.int2, idsSampleRate, siemensSampleRate);
% 帮助文档：If x is not slowly varying, consider using interp1 with the "pchip" interpolation method.
siemensInterp.time = idsData.Time;
siemensInterp.disp1 = interp1(siemensData.time, siemensData.disp1, siemensInterp.time, "pchip");
siemensInterp.disp2 = interp1(siemensData.time, siemensData.disp2, siemensInterp.time, "pchip");
siemensInterp.int1 = interp1(siemensData.time, siemensData.int1, siemensInterp.time, "pchip");
siemensInterp.int2 = interp1(siemensData.time, siemensData.int2, siemensInterp.time, "pchip");


% take the geometric error into account
geometricError1 = ppval(geometric_error_pp, siemensInterp.disp1);
geometricError2 = ppval(geometric_error_pp, siemensInterp.disp2);
siemensInterp.disp1 = siemensInterp.disp1 - geometricError1;
siemensInterp.disp2 = siemensInterp.disp2 - geometricError2;

%% 位移平移：与IDS的时间对齐
y = { ...
    siemensInterp.disp1, ...
    siemensInterp.disp2, ...
    siemensInterp.int1, ...
    siemensInterp.int2 ...
    };

% 互相关对齐
% figure;
% findpeaks(-1 * idsData.Displacement, 'MinPeakProminence', 10, 'MinPeakDistance', 0.01);
% hold on;
% findpeaks(idsData.Displacement, 'MinPeakProminence', 10, 'MinPeakDistance', 0.01);
% [~, locs1] = findpeaks(-1 * idsData.Displacement, 'MinPeakProminence', 10, 'MinPeakDistance', 0.01);
% [~, locs2] = findpeaks(idsData.Displacement, 'MinPeakProminence', 10, 'MinPeakDistance', 0.01);
% locsMin = min([locs1, locs2]);
[corrValue, lags] = xcorr(y{1}, idsData.Displacement); % y相对于x的延迟，用开始第一段加减速算对齐
[~, maxIndex] = max(abs(corrValue));
delaySamples = lags(maxIndex);
delayTime = delaySamples / idsSampleRate;
% delayTime = 21.5661 - 26.8895;
% delaySamples = round(delayTime * idsSampleRate);
[ids_aligned, y_aligned] = time_align(idsData.Displacement, y, delayTime, delaySamples);
time_aligned = (0:length(ids_aligned) - 1) / idsSampleRate;

% 辅助对齐：互相关结果不如意
% for ii = 1:length(ids_aligned)
% 
% end
% [maxMissalignValue, maxMissalignIdx] = max(y_aligned{1} - ids_aligned);

figure('Name','互相关结果');
tiledlayout(3, 1);
nexttile;
stem(lags, corrValue);
nexttile;
plot(idsData.Time, idsData.Displacement, 'DisplayName', 'Raw IDS');
hold on;
plot(siemensInterp.time, siemensInterp.int1, 'DisplayName', 'Raw Siemens');
legend;
nexttile;
plot(time_aligned, ids_aligned, 'DisplayName', 'Aligned IDS');
hold on;
plot(time_aligned, y_aligned{1}, 'DisplayName', ' Aligned Siemens 1');
plot(time_aligned, y_aligned{3}, 'DisplayName', ' Aligned Siemens 3');
legend;
drawnow;

idsData.Time = time_aligned;
idsData.Displacement = ids_aligned;

siemensInterp.time = time_aligned;
siemensInterp.disp1 = y_aligned{1};
siemensInterp.disp2 = y_aligned{2};
siemensInterp.int1 = y_aligned{3};
siemensInterp.int2 = y_aligned{4};

%% IDS velocity and acceleration
% ------------ 计算滤波后的速度 ------------
idsData.veloTime = 0.5 * (downsampleTime(1:end - 1) + downsampleTime(2:end));
idsData.velo = 60 * diff(downsampleDisp) ./ diff(downsampleTime);

% 三次样条加权平滑
sp = spaps(idsData.veloTime, idsData.velo, 5000000, [], 2);
idsData.velo_filtered = fnval(sp, idsData.veloTime);

% 计算加速度
idsData.accelTime = 0.5 * (idsData.veloTime(1:end - 1) + idsData.veloTime(2:end));
idsData.accel = diff(idsData.velo_filtered) ./ diff(idsData.veloTime) ./ 60000;

%% CNC velocity and acceleration
% （无需滤波和降采样的话）计算原始速度，并画图
siemensInterp.veloTime = 0.5 * (siemensInterp.time(1:end - 1) + siemensInterp.time(2:end));
siemensInterp.velo1 = 60 * diff(siemensInterp.disp1)./diff(siemensInterp.time);
siemensInterp.velo2 = 60 * diff(siemensInterp.disp2)./diff(siemensInterp.time);

siemensInterp.intVelo1 = 60 * diff(siemensInterp.int1)./diff(siemensInterp.time);
siemensInterp.intVelo2 = 60 * diff(siemensInterp.int2)./diff(siemensInterp.time);

% 样条拟合平滑
sp = spaps(siemensInterp.veloTime, siemensInterp.velo1, 10000, [], 2);
siemensInterp.velo1_filtered = fnval(sp, siemensInterp.veloTime);
sp = spaps(siemensInterp.veloTime, siemensInterp.velo2, 10000, [], 2);
siemensInterp.velo2_filtered = fnval(sp, siemensInterp.veloTime);
clear sp;

% 计算加速度
siemensInterp.accelTime = 0.5 * (siemensInterp.veloTime(1:end - 1) + siemensInterp.veloTime(2:end));
siemensInterp.accel1 = diff(siemensInterp.velo1_filtered) ./ diff(siemensInterp.veloTime) ./ 60000;
siemensInterp.accel2 = diff(siemensInterp.velo2_filtered) ./ diff(siemensInterp.veloTime) ./ 60000;
siemensInterp.intAccel1 = diff(siemensInterp.intVelo1) ./ diff(siemensInterp.veloTime) ./ 60000;
siemensInterp.intAccel2 = diff(siemensInterp.intVelo2) ./ diff(siemensInterp.veloTime) ./ 60000;

%% 画图

% 对比四个图，哪个的偏差比较合适作图就用哪个
% 理论上，插补是离散化后的阶梯状曲线，并不适合作为理论值；用补偿几何误差后的光栅尺更合适
% 但是，实际上，更合适的情况却是，用disp做互相关分析，然后用int作图。这样误差在1mm左右；反过来的话误差就是5mm了
figure;
tiledlayout(4, 1);
nexttile;
plot(idsData.Time, idsData.Displacement - siemensInterp.disp1);
nexttile;
plot(idsData.Time, idsData.Displacement - siemensInterp.disp2);
nexttile;
plot(idsData.Time, idsData.Displacement - siemensInterp.int1);
nexttile;
plot(idsData.Time, idsData.Displacement - siemensInterp.int2);
drawnow;

%% 论文图
% figure('Name','Displacement Comparison');
% tiledlayout(2, 1);
% ax1 = nexttile;
% plot(idsData.Time, idsData.Displacement);
% hold on;
% plot(siemensInterp.time, siemensInterp.disp1);
% ax2 = nexttile;
% plot(idsData.Time, idsData.Displacement - siemensInterp.disp1);
% linkaxes([ax1, ax2], 'x');
% drawnow;

lineColorIDS = [0 0.4470 0.7410];
lineWidthIDS = 1;
lineColorSie = [0.8500 0.3250 0.0980];
lineWidthSie = 0.5;
faceColor = [0.929                     0.694                     0.125];
faceAlpha = 1;

figure('Name','Displacement Comparison Bar');
tiledlayout(3, 1);
ax1 = nexttile;
colororder([lineColorIDS; faceColor]);
yyaxis left;
plot(idsData.Time, idsData.Displacement, 'LineWidth', lineWidthIDS, 'Color', lineColorIDS);
hold on;
plot(siemensInterp.time, siemensInterp.disp1, ...
    'LineWidth', lineWidthSie, 'LineStyle', '-', 'Color', lineColorSie);
ylim([-3500, 500]);
% set(gca, 'XTickLabel', [], 'YTickLabel', []);
yyaxis right;
bar(idsData.Time, idsData.Displacement - siemensInterp.disp1, 1, 'BaseValue', 0, ...
    'FaceColor', faceColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
ylim1 = [-1.5, 1.5];
ylim(ylim1);
% set(gca, 'XTickLabel', [], 'YTickLabel', []);
set(gca, 'XTickLabel', []);

[dispmax, dispmaxInd] = max(abs(idsData.Displacement - siemensInterp.disp1))

ax2 = nexttile;
colororder([lineColorIDS; faceColor]);
yyaxis left;
plot(idsData.veloTime, idsData.velo_filtered, 'LineWidth', lineWidthIDS, 'Color', lineColorIDS);
hold on;
plot(siemensInterp.veloTime, siemensInterp.velo1_filtered, ...
    'LineWidth', lineWidthSie, 'LineStyle', '-', 'Color', lineColorSie);
% set(gca, 'XTickLabel', [], 'YTickLabel', []);
yyaxis right;
bar(idsData.veloTime, idsData.velo_filtered - siemensInterp.velo1_filtered, 1, 'BaseValue', 0, ...
    'FaceColor', faceColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
ylim2 = [-1500, 1500];
ylim(ylim2);
% set(gca, 'XTickLabel', [], 'YTickLabel', []);
set(gca, 'XTickLabel', []);

[velomax, velomaxInd] = max(abs(idsData.velo_filtered - siemensInterp.velo1_filtered))

ax3 = nexttile;
colororder([lineColorIDS; faceColor]);
yyaxis left;
plot(idsData.accelTime, idsData.accel, 'LineWidth', lineWidthIDS, 'Color', lineColorIDS);
hold on;
plot(siemensInterp.accelTime, siemensInterp.accel1, ...
    'LineWidth', lineWidthSie, 'LineStyle', '-', 'Color', lineColorSie);
% set(gca, 'XTickLabel', [], 'YTickLabel', []);
yyaxis right;
bar(idsData.accelTime, idsData.accel - siemensInterp.accel1, 1, 'BaseValue', 0, ...
    'FaceColor', faceColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
ylim3 = [-1, 1];
ylim(ylim3);
% set(gca, 'XTickLabel', [], 'YTickLabel', []);

[accelmax, accelmaxInd] = max(abs(idsData.accel - siemensInterp.accel1))

linkaxes([ax1 ax2 ax3], 'x');
xLim = get(gca, 'XLim');
return;

%% 
% [corrDisp, lagsDisp] = xcorr(siemensInterp.disp1, idsData.Displacement);
% figure;
% stem(lagsDisp, corrDisp, '.-');

%% 适应illustrator的论文图
close all;
figure;
colororder([lineColorIDS; faceColor]);
yyaxis left;
plot(idsData.Time, idsData.Displacement, 'LineWidth', lineWidthIDS, 'Color', lineColorIDS);
hold on;
plot(siemensInterp.time, siemensInterp.disp1, ...
    'LineWidth', lineWidthSie, 'LineStyle', '-', 'Color', lineColorSie);
xlim(xLim);
yyaxis right;
ylim(ylim1);
figure;
colororder([lineColorIDS; faceColor]);
yyaxis left;
plot(idsData.veloTime, idsData.velo_filtered, 'LineWidth', lineWidthIDS, 'Color', lineColorIDS);
hold on;
plot(siemensInterp.veloTime, siemensInterp.velo1_filtered, ...
    'LineWidth', lineWidthSie, 'LineStyle', '-', 'Color', lineColorSie);
xlim(xLim);
yyaxis right;
ylim(ylim2);
figure;
colororder([lineColorIDS; faceColor]);
yyaxis left;
plot(idsData.accelTime, idsData.accel, 'LineWidth', lineWidthIDS, 'Color', lineColorIDS);
hold on;
plot(siemensInterp.accelTime, siemensInterp.accel1, ...
    'LineWidth', lineWidthSie, 'LineStyle', '-', 'Color', lineColorSie);
xlim(xLim);
yyaxis right;
ylim(ylim3);

figure;
yyaxis right;
bar(idsData.Time, idsData.Displacement - siemensInterp.disp1, 1, 'BaseValue', 0, 'ShowBaseLine', 'on', ...
    'FaceColor', faceColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
ax = gca;
ax.XAxis.Visible = 'off';
ax.YAxis(1).Visible = 'off';
ax.YAxis(2).Visible = 'off';
fig = gcf;
set(gca, "XLim", xLim, "YLim", ylim1, "Position", [0, 0, 1, 1]);
figure;
yyaxis right;
bar(idsData.veloTime, idsData.velo_filtered - siemensInterp.velo1_filtered, 1, 'BaseValue', 0, 'ShowBaseLine', 'on', ...
    'FaceColor', faceColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
ax = gca;
ax.XAxis.Visible = 'off';
ax.YAxis(1).Visible = 'off';
ax.YAxis(2).Visible = 'off';
set(gca, "XLim", xLim, "YLim", ylim2, "Position", [0, 0, 1, 1]);
figure;
yyaxis right;
bar(idsData.accelTime, idsData.accel - siemensInterp.accel1, 1, 'BaseValue', 0, 'ShowBaseLine', 'on', ...
    'FaceColor', faceColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
ax = gca;
ax.XAxis.Visible = 'off';
ax.YAxis(1).Visible = 'off';
ax.YAxis(2).Visible = 'off';
set(gca, "XLim", xLim, "YLim", ylim3, "Position", [0, 0, 1, 1]);


%% 位移对齐函数
function [x_aligned, y_aligned] = time_align(x, y, delayTime, delaySamples)
% 位移平移：与IDS的时间对齐
% 对齐长度
if delayTime > 0
    for ii = 1:length(y)
        y_aligned{ii} = [y{ii}(delaySamples + 1:end), zeros(1, delaySamples)];
    end
    % x_aligned = x(1:end - delaySamples);
else
    for ii = 1:length(y)
        y_aligned{ii} = [zeros(1, -delaySamples), y{ii}(1:end + delaySamples)];
    end
    % x_aligned = x(-delaySamples + 1:end);
end
% 统一长度
min_len = min(length(x), length(y_aligned{1}));
x_aligned = x(1:min_len);
for ii = 1:length(y)
    y_aligned{ii} = y_aligned{ii}(1:min_len);
end
end