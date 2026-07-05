%% Analysis of data exported from XL-80 or IDS-3010
% 

close all;
clear; clc;
cd(fileparts(which("start_up.m")));
tic;

set(groot, 'DefaultAxesFontName', 'Times New Roman', 'DefaultAxesFontSize', 12);
set(groot, 'DefaultTextFontName', 'Times New Roman', 'DefaultTextFontSize', 12);
set(groot, 'DefaultAxesXMinorTick', 'on');

GEOMETRIC_ERROR_MAP = '../machine-tool-error-core/data/hmms6000/X_positioning_error.mat';

%% --------------------------- Data Import ---------------------------

defaultPath = char('D:\Sync\syncthing\Data\202406-mms-dynamics\ids results mat\20240530 IDS\XD_Y3000_A3J80.mat');
% defaultPath = char('D:\Sync\syncthing\Data\202406-mms-dynamics\xl80 results\20240530 xl80\XD-Y0_A3J80.csv');
[fileName, fileLocatiion, idx] = uigetfile({ ...
    '*.mat', 'MAT files'; ...
    '*.csv', 'comma-separated-value files'; ...
    '*.*', 'All files' ...
    }, 'Select the data file', defaultPath);
FILE_PATH = fullfile(fileLocatiion, fileName);

switch idx
    case 1
        % .mat file
        measData = load(FILE_PATH);
        % measData = struct2table(measData); 
    case 2
        % .csv file: xl-80 results
        fid = fopen(FILE_PATH);
        for ii = 1:100
            tline = fgetl(fid);
            if contains(tline, 'Time, Measurement')
                break;
            end
        end
        fclose(fid);
        
        opts = detectImportOptions(FILE_PATH, "FileType", "delimitedtext", "NumHeaderLines", ii - 1);
        dataTable = readtable(FILE_PATH, opts);
        measData = struct("Time", dataTable.Time, "Displacement", dataTable.Measurement);
        measData.Displacement = -1.*measData.Displacement;
end

% Fetch the theoretical acceleration from the name of the file
theoAccelPattern = 'A(\d+)'; % 匹配"A"后面的数字
match = regexp(fileName, theoAccelPattern, 'tokens');
theoAccel = str2double(match{1}{1});
clear theoAccelPattern match;

% Parameters for character extraction
DISP_MinPeakProminence = 10; % Measured point A, B, D
VELO_MinPeakProminence = 10;
ACCEL_MinPeakProminence = 0.5;
isFluctuation = false; % false for measured A, B, C, and J5 in D;
%% --------------------------- 位移数据处理：开始方向确认 ---------------------------
% 不同的数据，测量的开始位置和方向并未统一，需要在此统一为：
% 
% X轴数据以X=-1000为起点沿负方向遍历，Y轴数据以Y=0为起点沿正方形遍历（即与几何误差表一致）  
% 
% *不同测点的情况会有不同，在换测点时必须留意此处！！！！！*
% 
% *X轴A、D测点只需要将起始点平移到X=-1000即可*
% 
% *X轴B测点需取反，再将起始点平移到X=-3000*
% 
% *X轴C测点*

% X轴A、D测点：X=-1000~X=-5500
% measData.Displacement = measData.Displacement - 1000 + measData.Displacement(1);
% X轴B测点：X=-3000~X=-7000
% measData.Displacement = -1 * measData.Displacement - 3000 + measData.Displacement(1);
% X轴C测点：X=-4200~X=-4300
% measData.Displacement = -1 * measData.Displacement - 4200 + measData.Displacement(1);
% X轴C测点：X=-6900~X=-7000
% measData.Displacement = -1 * measData.Displacement - 6900 + measData.Displacement(1);

fig1 = figure('Name', '【IDS】位移原始图像');
ax1 = axes(fig1);
plot(ax1, measData.Time, measData.Displacement);
hold(ax1, "on");
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Displacement (mm)');
drawnow;

clear fig1 ax1;
%% --------------------------- Positioning Error Removal, Downsampling, and Filtering ---------------------------

% ------------ Positioning Error Removal of Displacement ------------
measData.DispWithPosErr = measData.Displacement;
measData.Displacement = remove_positioning_error(measData.Time, measData.DispWithPosErr, GEOMETRIC_ERROR_MAP);

% ------------ Denoise ------------
filterData = filter_kinematic_signal(measData);
%% --------------------------- 输入输出信号的低通滤波（deprecated） ---------------------------

% fc = 5;
% % 输入信号分解
% x_sig_est = lowpass(diff(filterData.Displacement), fc, 1/(filterData.Time(2) - filterData.Time(1)));
% x_noise_est = diff(filterData.Displacement) - x_sig_est;
% 
% % 输出信号分解
% y_sig_est = lowpass(filterData.velo, fc, filterData.sampleRate);
% y_noise_est = filterData.velo - y_sig_est;
% 
% snr_in_est  = 10*log10(sum(x_sig_est.^2) / sum(x_noise_est.^2));
% snr_out_est = 10*log10(sum(y_sig_est.^2) / sum(y_noise_est.^2));
% snr_gain_est = snr_out_est - snr_in_est;
% 
% figure; 
% plot(theo_accelTime, theo_accel);
% plot(theo_veloTime, theo_velo);
% hold on;
% plot(filterData.accelTime, filterData.accel);
% 画加速度原始图像
% fig5 = figure('name', '【IDS】加速度图像');
% hLine = plot(filterData.accelTime, filterData.accel, 'LineWidth', 1);
% hAxes = ancestor(hLine, 'Axes');
% hold on;
% % title(hAxes, 'Acceleration 1 vs 2');
% ylim([min(filterData.accel), max(filterData.accel)]);
% xlabel('Time (s)');
% ylabel('Acceleration (m/s^2)');
%% --------------------------- 位移分段分析 ---------------------------
% 使用findpeaks函数，排除噪声并寻找所有局部最值。计算局部最值离理想值的差值，作为偏差

shiftTime = ceil(0.1 * filterData.sampleRate); % the time interval around the peak/valley value
dispPeaks = peak_segmentation(filterData.Time, filterData.Displacement, [], ...
    "IsNormalization", false, "MinPeakProminence", DISP_MinPeakProminence);
% calculate the disprange
dispPeaks.dispRange(:, 1) = dispPeaks.ind - shiftTime;
dispPeaks.dispRange(:, 2) = dispPeaks.ind + shiftTime + 1;
% add a line in the end, which is more convenient to be copied into excel
tmp = table(NaN, NaN, NaN, NaN, NaN, NaN, NaN, [NaN, NaN], 'VariableNames', dispPeaks.Properties.VariableNames);
dispPeaks(end + 1, :) = tmp; 
if strcmp(fileName(2), 'C')
    % if Measured point C, then eliminate the final peak value of each segment
    dispPeaksforAccel = dispPeaks;
    peakLength = size(dispPeaks, 1);
    for ii = 12 .* (1:floor(peakLength / 12))
        dispPeaks(ii, :) = tmp;
    end
end

plot_peaks(filterData.Time, filterData.Displacement, dispPeaks(1:2:end - 1, :), dispPeaks(2:2:end, :), ...
    "PlotName", "位移峰值");
drawnow;
%% --------------------------- 速度指标计算 ---------------------------

ADJACENT_PARAM = 0.2 * filterData.sampleRate; % A3J5要改成1 * filterData.sampleRate
% Extract velocity segments from the signal
[velocitySegment, desiredValue, tLim1End] = velocity_segmentation(filterData.velo, ADJACENT_PARAM, 'case', 'IDS');

% Draw each segments of the velocity signal
fig5 = figure('Name', '【IDS】速度指标计算');
figPos = get(fig5, "Position");
screenPos = get(0, 'ScreenSize');
set(fig5, "Position", [figPos(1), figPos(2) - figPos(4), figPos(3), figPos(4)]);
t1 = tiledlayout(fig5, 3, 1, "TileSpacing", "tight", 'Padding', 'tight');
n1 = nexttile(t1, 1, [2, 1]);
hLine = plot(filterData.veloTime, filterData.velo, 'LineWidth', 0.5, 'DisplayName', 'Velocity');
hold on;
for ii = 1:length(desiredValue)
    % if ~isnan(desiredValue(ii))
        plotObj = plot(filterData.veloTime(velocitySegment(ii, 1):velocitySegment(ii, 2)), ...
            filterData.velo(velocitySegment(ii, 1):velocitySegment(ii, 2)), ...
            'LineWidth', 1.25, 'LineStyle', '--');
        plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
    % end
end
sca1 = scatter(filterData.veloTime(velocitySegment(:, 1)), filterData.velo(velocitySegment(:, 1)), ...
    36, 'MarkerEdgeColor', [0.8500 0.3250 0.0980], 'MarkerFaceColor', [0.8500 0.3250 0.0980], ...
    'DisplayName', 'Strat Location', 'Marker', 'o');
sca2 = scatter(filterData.veloTime(velocitySegment(:, 2)), filterData.velo(velocitySegment(:, 2)), ...
    12, 'MarkerEdgeColor', [0.9290 0.6940 0.1250], 'MarkerFaceColor', [0.9290 0.6940 0.1250], ...
    'DisplayName', 'End Location', 'Marker', 'o');
legend('Location', 'best');
% title(n1, 'Segmented Velocity');
hAxes = ancestor(hLine, 'Axes');
tLim = [0, filterData.veloTime(tLim1End) + 5];
plotObj = plot(tLim, [5000, 5000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim, [-5000, -5000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim, [30000, 30000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
plotObj = plot(tLim, [-30000, -30000], 'LineStyle', '--', 'LineWidth', 0.25, 'Color', [0.4, 0.4, 0.4]);
plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
hAxes.XLim = tLim;
ylabel('Velocity (mm/min)');

% Initialize for the velocity parameter struct, then changed into table
veloParam = struct("peakValue", {}, "peakError", {}, "peakMoment", {}, ...
    "steadyStateValue", {}, "steadyStateError", {}, "steadyStateMoment", {}, ...
    "riseTime", {}, "noiseLevel", {}, "overshoot", {}, ...
    "oscillationFrequency", {}, "settlingTime", {}, ...
    "peakValue0", {}, "peakError0", {}, "peakMoment0", {});

% A different method is used for thee measurement point D
% if strcmp(fileName(2), 'D')
%     isFluctuation = true;
% else
%     isFluctuation = false;
% end

% Calculate the velocity parameters for each segments
for ii = 1:size(velocitySegment, 1)
    % diffVelocitySegment = velocitySegment1(ii + 1) - velocitySegment1(ii);
    % if diffVelocitySegment > 1
    %     desiredValue = 5000; 
    % end
    % determine the desired value
    veloParam(ii) = velo_param( ...
        filterData.veloTime(velocitySegment(ii, 1):velocitySegment(ii, 2)), ...
        filterData.velo(velocitySegment(ii, 1):velocitySegment(ii, 2)), desiredValue(ii), ...
        'MinPeakProminence', VELO_MinPeakProminence, "Fluctuation", isFluctuation);
    % plotting for debug
    % plotObj = scatter(filterData.veloTime(velocitySegment(ii, 1)) + veloParam(ii).peakMoment, ...
    %     veloParam(ii).peakValue);
    % plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
    % plotObj = scatter(filterData.veloTime(velocitySegment(ii, 2)) - veloParam(ii).peakMoment0, ...
    %     veloParam(ii).peakValue0);
    % plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
    % drawnow;
end

% Add the item "startMoment" for each elements, and all the time-variables should be shifted 
%   considering the effect of the small overshoot at the beginning of the velocity-shifting process
for ii = 2:size(velocitySegment, 1)
    veloParam(ii).startMoment = filterData.veloTime(velocitySegment(ii, 1)) - veloParam(ii - 1).peakMoment0;
    veloParam(ii).startValue = veloParam(ii - 1).peakValue0;
    veloParam(ii).steadyStateMoment = veloParam(ii).steadyStateMoment + veloParam(ii - 1).peakMoment0;
    veloParam(ii).peakMoment = veloParam(ii).peakMoment + veloParam(ii - 1).peakMoment0;
    veloParam(ii).riseTime = veloParam(ii).riseTime + veloParam(ii - 1).peakMoment0;
    veloParam(ii).settlingTime = veloParam(ii).settlingTime + veloParam(ii - 1).peakMoment0;
end

% the startmoment of the first segment should be calculated here, i.e., the peak location before the 1st segment
[~, ind] = findpeaks(abs(filterData.velo(1:velocitySegment(1, 1))), "NPeaks", 1, 'SortStr', 'descend');
veloParam(1).startMoment = filterData.veloTime(ind);
veloParam(1).startValue = filterData.velo(ind);
deltaMoment = filterData.veloTime(velocitySegment(1, 1) - ind);
veloParam(1).steadyStateMoment = veloParam(1).steadyStateMoment + deltaMoment;
veloParam(1).peakMoment = veloParam(1).peakMoment + deltaMoment;
veloParam(1).riseTime = veloParam(1).riseTime + deltaMoment;
veloParam(1).settlingTime = veloParam(1).settlingTime + deltaMoment;

drawnow;
pause(2);
delete(sca1); delete(sca2);
scatter([veloParam.startMoment], [veloParam.startValue], 36, ...
    'MarkerEdgeColor', [0.8500 0.3250 0.0980], 'MarkerFaceColor', [0.8500 0.3250 0.0980], ...
    'DisplayName', 'Seperate Location', 'Marker', 'diamond', 'MarkerFaceAlpha', 0.3);
% plotObj = line(meshgrid([veloParam.startMoment], 1:2), max(filterData.velo) * ndgrid([-1, 1], 1:38), ...
%     "Color", [0.8500 0.3250 0.0980], "LineStyle", "-.");
% plotObj.Annotation.LegendInformation.IconDisplayStyle = "off";
scatter([veloParam.startMoment] + [veloParam.peakMoment], [veloParam.peakValue], 36, ...
    'MarkerEdgeColor', [0.9290 0.6940 0.1250], 'MarkerFaceColor', [0.9290 0.6940 0.1250], ...
    'DisplayName', 'Peaks', 'Marker', 'o', 'MarkerFaceAlpha', 0.3);
scatter([veloParam.startMoment] + [veloParam.steadyStateMoment], [veloParam.steadyStateValue], 36, ...
    'MarkerEdgeColor', [0.4660 0.6740 0.1880] * 0.5, ...
    'DisplayName', 'Steady State', 'Marker', '*');

% change the data structure from struct to table, which is easier to duplicate
veloParam = struct2table(veloParam);

% 画图展示速度评价参数
nexttile(t1, 3);
yyaxis left;
bar(filterData.veloTime(velocitySegment(:, 1)), veloParam.peakError, 1, "LineStyle", "none");
ylabel('Peak error (mm/min)');
xlabel('Time (s)');
yyaxis right;
plot(filterData.veloTime(velocitySegment(:, 1)), 100*veloParam.overshoot, ...
    "Marker", "diamond", "Color", [0.8500 0.3250 0.0980], ...
    "MarkerEdgeColor", [0.8500 0.3250 0.0980], "MarkerFaceColor", [0.8500 0.3250 0.0980]);
ylabel('Overshoot');
ytickformat('%.1g%%');
xlim(tLim);
legend("Peak error", "Overshoot percent", "Location", "best");
% nexttile(t1, 10, [1, 1]);
% yyaxis left;
% plot(filterData.veloTime(velocitySegment(:, 1)), veloParam.riseTime, 'o-', ...
%     'MarkerSize', 3, "MarkerFaceColor", [0 0.4470 0.7410]);
% hold on;
% yyaxis right;
% plot(filterData.veloTime(velocitySegment(:, 1)), veloParam.settlingTime, 'square-', ...
%     'MarkerSize', 3, "MarkerFaceColor", [0.8500 0.3250 0.0980]);
% xlim(tLim);
% legend("Rising time", "Setting time", "Location", "best");
% nexttile(t1, 11, [1, 1]);
% plot(filterData.veloTime(velocitySegment(:, 1)), veloParam.noiseLevel, ...
%     "Marker", "o", "MarkerSize", 3);
% xlim(tLim);
% legend("Noise level", "Location", "best");
% nexttile(t1, 12, [1, 1]);
% plot(filterData.veloTime(velocitySegment(:, 1)), veloParam.oscillationFrequency, ...
%     "Marker", "o", "MarkerSize", 3);
% xlim(tLim);
% legend("Oscillation frequency", "Location", "best");
drawnow;
%% ------------------------------ 加速度指标计算 ------------------------------
% 由于加速度数据的鲁棒性远远不及位移和速度，故分段和指标计算后的数据，单独检查后再拷贝到excel文件中

[accelPeaks, accelValleys] = peak_segmentation(filterData.accelTime, filterData.accel, ...
    theoAccel, "PlotName", "【IDS】加速度峰谷值", "MinPeakDistance", ACCEL_MinPeakProminence);
drawnow;
%% --------------------------------- 指标整理 ---------------------------------
% 位移、速度指标按Excel记录表格整理

paramExcel = save_excel(dispPeaks, veloParam);

% 加速度指标另外计算
num = size(paramExcel, 1);
if strcmp(fileName(2), 'C')
    accelExcel = accel_param2excel_C(filterData.accelTime, filterData.accel, num, ...
        accelPeaks, accelValleys, dispPeaksforAccel, "PlotName", "【IDS】加速度数据提取动画");
else
    accelExcel = accel_param2excel(filterData.accelTime, filterData.accel, num, ...
        accelPeaks, accelValleys, dispPeaks, "PlotName", "【IDS】加速度数据提取动画");
end

% 合并加速度表格和位移速度表格
paramExcel = [paramExcel, accelExcel];
%% ----------------------------------- 收尾 -----------------------------------

[pathstr, name, ~] = fileparts(FILE_PATH);
filePath1 = fullfile(pathstr, name);
% if ~isfolder(filePath1)
%     mkdir(filePath1);
% end
% fig_save(filePath1);

% 图像平铺
% fig_tiled;
% fig_modal;

fprintf("The data extraction process for the file %s is completed. \n", fileName);
t = toc