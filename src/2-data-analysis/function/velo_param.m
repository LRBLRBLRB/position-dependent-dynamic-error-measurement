function [paramTable] = velo_param(time,signal,desiredValue,options)
%VELO_PARAM 
%   Separate the velocity signal to obtain division of each segments, while 
%   calculate the parameters of a velocity curve

arguments
    time
    signal
    desiredValue
    options.SettingPercent = 0.05
    options.MinPeakProminence = 0
    options.Fluctuation = false
end

%% set the end of the velocity segment


%% stopped parameter calculation
% if isnan(desiredValue)
%     [~,ind] = max(abs(signal(round(end/2):end)));
%     paramTable = struct("peakValue",signal(round(end/2) + ind), ...
%         "peakError",NaN, "peakMoment", time(round(end/2) + ind), ...
%         "steadyStateValue",NaN,"steadyStateError",NaN, ...
%         "riseTime",NaN,"noiseLevel",NaN,"overshoot",NaN, ...
%         "oscillationFrequency",NaN,"settlingTime",NaN);
%     return;
% end

% 【峰值】、【峰值时间】
% [peakValue0, peakMoment0]: the peak situation of the start stage of the velocity shifting process
if options.Fluctuation
    if signal(1) < signal(end)
        [peakValue,peakInd] = max(signal);
    else
        [peakValue,peakInd] = min(signal);
    end
    peakInd0 = length(signal);
    peakValue0 = signal(end);
else
    if signal(1) < signal(end)
        % [peakValue, peakMoment] = max(signal);
        [peakValue, peakInd] = findpeaks(signal, "NPeaks", 1, "SortStr", "none", "MinPeakProminence", options.MinPeakProminence);
        [peakValue0, peakInd0] = findpeaks(flip(signal), "NPeaks", 1, "SortStr", "none", "MinPeakProminence", options.MinPeakProminence);
        peakInd0 = length(signal) - peakInd0 + 1;
        if isempty(peakValue) || (max(peakValue, peakValue0) < max(signal))
            [peakValue, peakInd] = max(signal);
            [peakValue0, peakInd0] = max(signal);
        end
    else
        % [peakValue, peakMoment] = min(signal);
        [peakValue, peakInd] = findpeaks(-1 .* signal, "NPeaks", 1, "SortStr", "none", "MinPeakProminence", options.MinPeakProminence);
        peakValue = -1 .* peakValue;
        [peakValue0, peakInd0] = findpeaks(flip(-1 .* signal), "NPeaks", 1, "SortStr", "none", "MinPeakProminence", options.MinPeakProminence);
        peakValue0 = -1 .* peakValue0;
        peakInd0 = length(signal) - peakInd0 + 1;
        if isempty(peakValue) || (min(peakValue, peakValue0) > min(signal))
            [peakValue, peakInd] = min(signal);
            [peakValue0, peakInd0] = min(signal);
        end
    end
end

peakMoment = time(peakInd) - time(1);
peakMoment0 = time(end) - time(peakInd0);

% % 【峰值】
% if signal(1) < signal(end)
%     % [peakValue,peakMoment] = max(signal);
%     [tmpPks, tmpLocs] = findpeaks(signal, "NPeaks", 2, "SortStr", "descend");
% else
%     % [peakValue,peakMoment] = min(signal);
%     [tmpPks, tmpLocs] = findpeaks(-1 .* signal, "NPeaks", 2, "SortStr", "descend");
%     tmpPks = -1 .* tmpPks;
% end
% 
% % 【峰值】、【峰值时间】
% [peakInd, tmpInd] = min(tmpLocs);
% peakValue = tmpPks(tmpInd);
% peakMoment = time(peakInd) - time(1);
% 
% % the peak situation of the start stage of the velocity shifting process
% if isscalar(tmpPks) % 超调未能显示出来，只有一个峰值的情况
%     peakInd0 = peakInd;
%     tmpInd0 = tmpInd;
% else
%     [peakInd0, tmpInd0] = max(tmpLocs);
% end
% peakValue0 = tmpPks(tmpInd0);
% peakMoment0 = time(end) - time(peakInd0);

% 【稳态值】、【稳态时间】
if isnan(desiredValue) % 速度开始变化时有超调，但稳态值未达到desiredValue的情况
    steadyStateValue = peakValue;
    steadyStateMoment = peakMoment;
else % 最正常的情况：速度开始变化和结束变化时均有超调，且稳态值达到了desiredValue
    tmpInd = find(abs(signal(1:peakInd0) - desiredValue) < 0.1, 1, "last");
    steadyStateInd = find(abs((signal(peakInd:tmpInd) - desiredValue) / (signal(1) - desiredValue)) ...
        > 0.002, 1, "last");
    if isempty(steadyStateInd)
        [~, steadyStateInd] = max(abs(signal(peakInd:peakInd0)));
    end
    steadyStateValue = signal(peakInd + steadyStateInd - 1);
    steadyStateMoment = time(peakInd + steadyStateInd - 1) - time(1);
end


% 【峰值误差】
peakError = peakValue - desiredValue;
peakError0 = peakValue0 - desiredValue;

% 【稳态误差】是稳态值与期望值（假设为 desired_value）之间的误差：
steadyStateError = steadyStateValue - desiredValue;

% 【上升时间】定义为信号从 10% 上升到 90% 稳态值所需的时间：
riseTimeEnd = find( ...
    abs(signal - steadyStateValue) <= 0.1 * abs(signal(1) - steadyStateValue),1);
riseTime = time(riseTimeEnd) - time(1);
if isempty(riseTime)
    riseTime = NaN;
end

% 【噪声水平】可以用信号在稳态时的标准差表示
noiseLevel = std(signal(end-round(length(signal)*0.1):end));

% 【过冲】是信号超过稳态值的最大值，通常用百分比表示：
overshoot = (peakValue - steadyStateValue) / steadyStateValue;

% 【振荡频率】可以通过分析信号的频谱来估计
Fs = 1 / mean(diff(time)); % 采样频率
Y = fft(signal);
L = length(signal);
P2 = abs(Y/L);
P1 = P2(1:round(L/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:round(L/2))/L;
[~, max_index] = max(P1);
oscillationFrequency = f(max_index); % 改

% 减时间是信号进入并保持在稳态范围内（例如稳态值的 2% 范围内）所需的时间
settlingTimeIndex = find( ...
    abs(signal - steadyStateValue) <= ...
    options.SettingPercent * abs(signal(1) - steadyStateValue), ...
    1,'last');
settlingTime = time(settlingTimeIndex) - time(1);
if isempty(settlingTime)
    settlingTime = NaN;
end

% 组装成表结构，以避免部分数据为空时输出数组维度不对应
% paramName = ["peakValue","steadyStateValue","riseTime","steadyStateError", ...
%     "noiseLevel","overshoot","oscillationFrequency","settlingTime"];
% paramVector = [peakValue,steadyStateValue,riseTime,steadyStateError, ...
%     noiseLevel,overshoot,oscillationFrequency,settlingTime];
paramTable = struct("peakValue", peakValue, ...
    "peakError", peakError, ...
    "peakMoment", peakMoment, ...
    "steadyStateValue", steadyStateValue, ...
    "steadyStateError", steadyStateError, ...
    "steadyStateMoment", steadyStateMoment, ...
    "riseTime", riseTime, ...
    "noiseLevel", noiseLevel, ...
    "overshoot", overshoot, ...
    "oscillationFrequency", oscillationFrequency, ...
    "settlingTime", settlingTime, ...
    "peakValue0", peakValue0, ...
    "peakError0", peakError0, ...
    "peakMoment0", peakMoment0);
end