function filterData = filter_kinematic_signal(measData,options)
%FILTER_KINEMATIC_SIGNAL filter and differentiate to obtain kinematic
%signals from the original displacement signals
arguments (Input)
    measData (1,1) struct {mustBeMeasData}
    options.waveName = 'sym9' % 小波基
    options.waveletMethod='Bayes'
    options.waveletThresholdRule='Soft'
    options.noiseEstimate='LevelIndependent'
    options.downSampleRate = 10;
end

%% ---------------------------------- Calculation from Displacement to Velocity ----------------------------------

% ------------ Denoise and Downsampling ------------
% if isempty(gcp('nocreate'))
%     parpool;
% end
% tmpDispSmooth = zeros(size(tmpDisp));
% block_size = 10000;
% num_blocks = ceil(length(tmpDisp) / block_size);
% % 并行分块处理数据
% tic
% for i = 1:num_blocks
%     temp_smooth = zeros(1, block_size);
% 
%     start_idx = (i-1) * block_size + 1;
%     end_idx = min(i * block_size, length(tmpDisp));
% 
%     temp_smooth(1:(end_idx-start_idx+1)) = smoothdata(tmpDisp(start_idx:end_idx), ...
%         'sgolay', 51, 'SamplePoints', tmpTime(start_idx:end_idx), 'Degree', 2);
%     tmpDispSmooth(start_idx:end_idx) = temp_smooth(1:(end_idx-start_idx+1));
% end
% toc
% tmpDispSmooth = smoothdata(tmpDisp, 'sgolay', 7, 'SamplePoints', tmpTime, 'Degree', 3);
% hold on;
% plot(tmpTime, tmpDispSmooth);

% Wavelet filtering for denoising
% decompose layer
NUM_LEVEL = min(21, wmaxlev(length(measData.Displacement),options.waveName)); 
dispWavelet = wdenoise(measData.Displacement,NUM_LEVEL, ...
    Wavelet=options.waveName, ...
    DenoisingMethod=options.waveletMethod, ...
    ThresholdRule=options.waveletThresholdRule, ...
    NoiseEstimate=options.noiseEstimate);

% dispWavelet = measData.Displacement;

% Data downsampling
downsampleTime = measData.Time(1:options.downSampleRate:end);
downsampleDisp = dispWavelet(1:options.downSampleRate:end);

% ------------ Velocity after Denoising ------------
measData.veloTime = 0.5 * (downsampleTime(1:end - 1) + downsampleTime(2:end));
measData.velo = 60 * diff(downsampleDisp) ./ diff(downsampleTime);

% 画位置和速度的滤波图像
figure('name', '位移滤波结果');
tiledlayout(2, 1);
ax1 = nexttile;
plot(measData.Time, measData.Displacement, 'DisplayName', 'Raw');
hold on;
plot(measData.Time, dispWavelet, 'DisplayName', 'Filtered');
legend;
ylabel('Displacement (mm)');
ax2 = nexttile;
plot(0.5 * (measData.Time(1:end - 1) + measData.Time(2:end)), ...
    60 * diff(measData.Displacement) ./ diff(measData.Time), ...
    'LineWidth', 1, 'DisplayName', 'Original');
hold on;
plot(measData.veloTime, measData.velo, 'LineWidth', 1, 'DisplayName', 'Filtered');
legend;
% ylim([min(measData.velo), max(measData.velo)]);
xlabel('Time (s)');
ylabel('Velocity (mm/min)');
linkaxes([ax1, ax2], 'x');
drawnow;

% 存储位移数据处理结果
filterData.Time = downsampleTime;
filterData.Displacement = downsampleDisp;
filterData.veloTime = measData.veloTime;

clear downsampleTime downsampleDisp dispWavelet ax2 fig2;

%% --------------------------- 速度滤波处理（为了加速度计算） ---------------------------
% 速度曲线滤波
% filterData.velo = measData.velo;
% 高斯滤波，不能解决匀加减速过程，或者匀速过程抖动对加速度计算的影响。
% siemensData.velo1 = filter_gaussian(100, 1, siemensData.velo);
% 三次样条加权平滑
% veloPeaks = peak_segmentation(measData.veloTime, measData.velo, [], ...
%     "IsNormalization", false, ...
%     "MinPeakDistance", 4, "MinPeakProminence", 10000, 'MinPeakWidth', 1);
% weights = ones(size(measData.veloTime));
% weightFactor = 1;
% weights(veloPeaks.ind) = weights(veloPeaks.ind) * weightFactor;
sp = spaps(measData.veloTime, measData.velo, 5000000, [], 2);
filterData.velo = fnval(sp, measData.veloTime);
% clear sp veloPeaks;
% 小波
% WAVE_NAME = 'sym9'; % 小波基
% NUM_LEVEL = min(21, wmaxlev(length(measData.velo),WAVE_NAME)); % 分解层数，越高越平滑
% filterData.velo = wdenoise(measData.velo, NUM_LEVEL, ...
%     Wavelet=WAVE_NAME, ...
%     DenoisingMethod='Bayes', ...
%     ThresholdRule='Soft', ...
%     NoiseEstimate='LevelIndependent');

% 计算加速度
filterData.accelTime = 0.5 * (filterData.veloTime(1:end - 1) + filterData.veloTime(2:end));
filterData.accel = diff(filterData.velo) ./ diff(filterData.veloTime) ./ 60000;

% 查看速度滤波的效果 （结果就是滤波作用不大）
figure('Name','速度滤波结果');
tiledlayout(3, 1);
ax1 = nexttile;
plot(measData.veloTime, measData.velo, 'DisplayName', 'Raw');
hold on;
plot(filterData.veloTime, filterData.velo, 'DisplayName', 'Filtered');
legend;
title('Velocity curve before & after filtering');
ylabel('Velocity (m/s^2)');
set(gca, "XTickLabel", []);

ax2 = nexttile;
plot(filterData.accelTime, diff(measData.velo) ./ diff(measData.veloTime) ./ 60000, ...
    "Color", [0, 0.4450, 0.7410]);
title('Acceleration curve before filtering');
ylabel('Acceleration (m/s^2)');
set(gca, "XTickLabel", []);

ax3 = nexttile;
plot(filterData.accelTime, diff(measData.velo) ./ diff(measData.veloTime) ./ 60000, ...
    'DisplayName', 'Original', "Color", [0, 0.4450, 0.7410] * 0.5 + [1, 1, 1] * 0.5);
hold on;
plot(filterData.accelTime, filterData.accel, 'DisplayName', 'Filtered');
ylim(1.1 * [min(filterData.accel), max(filterData.accel)])
title('Acceleration curve after filtering');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend;
linkaxes([ax1, ax2, ax3], 'x');
drawnow;
end

function mustBeMeasData(measData)
% set the required field of the struct measData
requiredFields = ["Time", "Displacement"];
actualFields = string(fieldnames(measData));

% check if there are missing fields
missingFields = setdiff(requiredFields, actualFields);

if ~isempty(missingFields)
    error("filter_kinematic_signal:InvalidMeasData", ...
        "Missing field of measData: %s", strjoin(missingFields, ", "));
end

% check if there are surplus fields
% extraFields = setdiff(actualFields, requiredFields);
% 
% if ~isempty(extraFields)
%     error("filter_kinematic_signal:InvalidMeasData", ...
%         "Extra fiels included in measData: %s", strjoin(extraFields, ", "));
% end

% check the field Time (numeric, vector
validateattributes(measData.Time, ...
    {'numeric'}, ...
    {'vector', 'real', 'finite', 'increasing'}, ...
    mfilename, 'measData.Time');

% check the field Displacement
validateattributes(measData.Displacement, ...
    {'numeric'}, ...
    {'vector', 'real', 'finite'}, ...
    mfilename, 'measData.Displacement');

% their length to be equal
if numel(measData.Time) ~= numel(measData.Displacement)
    error("filter_kinematic_signal:InvalidMeasData", ...
        "The length of measData.Time and measData.Displacement is expected to be equal");
end

end