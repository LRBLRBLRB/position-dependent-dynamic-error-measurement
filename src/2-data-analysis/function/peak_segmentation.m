function varargout = peak_segmentation(t, x, theoAccel, varargin)
%PEAK_SEGMENTATION  Extract speed-varying segments for displacement
% 
% Usage:
%   For displacement segmetation, 
%       dataPeaks = peak_segmentation(t, x)
%       dataPeaks = peak_segmentation(t, x, [], "Name", "Value")
%       [dataPeaks, dataValleys] = peak_segmentation(__)
%   For acceleration segmentation, 
%       dataPeaks = peak_segmentation(t, x, theoAccel)
%       dataPeaks = peak_segmentation(t, x, theoAccel, "Name", "Value")
%       [dataPeaks, dataValleys] = peak_segmentation(__)
% Inputs:
%   t       time array of the displacement signal
%   x       displacement array of the signal
%   theoAccel   theoretical acceleration
%   Name-Value options:
%       MinPeakHeight
%       MinPeakProminence
%       MinPeakDistance
%       MinPeakWidth
%       MaxPeakWidth
%       StratTime   the time interval before the first peak/valley
%       IsNormalization whether to delete the signal before StartTime or not
%       PlotName    the figure name of the peak plotting, and the plot function
%                   does not work if PlotName is empty
% Outputs:
%   dataPeaks   data structs of each peaks of speed-varying segments
%   dataValleys data structs of each valleys of speed-varying segments
%       each structs include elements:
%           pks2    peak value of each peak/valley
%           locs    locations of each peak value
%           w       each peak widths
%           p       each peak prominences. The prominence of a peak is the
%           minimum vertivcal distance that the signal must descent on either
%           side of the peak before either climbing back to a level higher than
%           the peak or reaching an endpoint.

if nargin < 3 || isempty(theoAccel)
    % displacement segmentation
    defaultMinPeakHeight = -Inf;
    defaultMinPeakProminence = 100;  % 修改默认值
    defaultMinPeakDistance = 0.01;   % 修改默认值
    defaultStartTime = 3;            % 修改默认值
    classStep = 100;
else
    % acceleration segmentation
    defaultMinPeakHeight = theoAccel*0.1;
    defaultMinPeakProminence = 0.5;
    defaultMinPeakDistance = 0.6;
    defaultStartTime = 3;
    classStep = theoAccel; % useless here
end

% 参数检查
p = inputParser;
addRequired(p, 't'); % the first required input, t, i.e., the time sequence
addRequired(p, 'x'); % the 2nd required input, x, i.e., the signal sequence
addOptional(p, 'theo_accel', 0); % optional input, only required during acceleration segmentation
addParameter(p, 'MinPeakHeight', defaultMinPeakHeight);
addParameter(p, 'MinPeakProminence', defaultMinPeakProminence);
addParameter(p, 'MinPeakDistance', defaultMinPeakDistance);
addParameter(p, 'StartTime', defaultStartTime);

addParameter(p, 'MinPeakWidth', 0);
addParameter(p, 'MaxPeakWidth', Inf);

addParameter(p, 'Display', false, @islogical);
addParameter(p, 'IsNormalization', false, @islogical);
addParameter(p, 'PlotName', [], @(x)isstring(x) || @(x)ischar(x));
parse(p, t, x, theoAccel, varargin{:});

if p.Results.Display
    disp(p.Results);
end

% 使用findpeaks函数检测局部最大值（峰值）
[pks1, locs1, w1, p1] = findpeaks(x, t, ...
    'MinPeakProminence', p.Results.MinPeakProminence, ...
    'MinPeakDistance', p.Results.MinPeakDistance, ...
    'MinPeakHeight', p.Results.MinPeakHeight, ...
    'MinPeakWidth', p.Results.MinPeakWidth, ...
    'MaxPeakWidth', p.Results.MaxPeakWidth);

% 使用findpeaks函数检测局部最小值（谷值），对信号取负值
[pks2, locs2, w2, p2] = findpeaks(-1 * x, t, ...
    'MinPeakProminence', p.Results.MinPeakProminence, ...
    'MinPeakDistance', p.Results.MinPeakDistance, ...
    'MinPeakHeight', p.Results.MinPeakHeight, ...
    'MinPeakWidth', p.Results.MinPeakWidth, ...
    'MaxPeakWidth', p.Results.MaxPeakWidth);

ind1 = zeros(size(locs1));
for ii = 1:length(locs1)
    ind1(ii) = find(t == locs1(ii));
end
ind2 = zeros(size(locs2));
for ii = 1:length(locs2)
    ind2(ii) = find(t == locs2(ii));
end

% 归一化：把每次实验的位移数据开始位置统一【结束不统一因为有的结束得太早了】
% start from the moment p.Results.StartTime
if p.Results.IsNormalization
    locMin = min(min(locs1), min(locs2)) - p.Results.StartTime;
    locMinInd = find(t <= locMin, 1, 'last');
    t = t(locMinInd + 1:end) - locMin;
    x = x(locMinInd + 1:end);
    % get the indices and locations of the peak and valley after substracting
    % the beginning point
    locs1 = locs1 - locMin;
    locs2 = locs2 - locMin;
    ind1 = ind1 - locMinInd;
    ind2 = ind2 - locMinInd;
end

% 把数据装载到datapeaks和datavalleys中，分别表示局部最大值参数和局部最小值参数
numElements = length(pks1);
dataPeaks(numElements) = struct();
for ii = 1:numElements
    dataPeaks(ii).pks = pks1(ii);
    dataPeaks(ii).locs = locs1(ii);
    dataPeaks(ii).w = w1(ii);
    dataPeaks(ii).p = p1(ii);
    dataPeaks(ii).ind = ind1(ii);
    dataPeaks(ii).class = round(dataPeaks(ii).pks / classStep) * classStep;
    dataPeaks(ii).error = dataPeaks(ii).pks - dataPeaks(ii).class;
end
dataPeaks = struct2table(dataPeaks);

numElements = length(pks2);
dataValleys(numElements) = struct();
for ii = 1:numElements
    dataValleys(ii).pks = -1*pks2(ii);
    dataValleys(ii).locs = locs2(ii);
    dataValleys(ii).w = w2(ii);
    dataValleys(ii).p = -1*p2(ii);
    dataValleys(ii).ind = ind2(ii);
    dataValleys(ii).class = round(dataValleys(ii).pks / classStep) * classStep;
    dataValleys(ii).error = dataValleys(ii).pks - dataValleys(ii).class;
end
dataValleys = struct2table(dataValleys);

% dataValleys = struct('pks', -1*pks2, 'locs', locs2, 'w', w2, 'p', -1*p2, 'ind', ind2);
% dataValleys.class = round(dataValleys.pks / 100) * 100;
% dataValleys.error = dataValleys.pks - dataValleys.class;

if ~isempty(p.Results.PlotName)
    plot_peaks(t, x, dataPeaks, dataValleys, "PlotName", p.Results.PlotName);
end

switch nargout
    case 1
        % combine the datapeaks and dataValleys into one sequence
        varargout{1} = [dataPeaks; dataValleys];
        varargout{1} = sortrows(varargout{1}, 'locs');
        % [varargout{1}.locs, sortInd] = sort([dataPeaks.locs; dataValleys.locs]);
        % tmp = [dataPeaks.ind; dataValleys.ind];
        % varargout{1}.ind = tmp(sortInd);
        % tmp = [dataPeaks.pks; dataValleys.pks];
        % varargout{1}.pks = tmp(sortInd);
        % tmp = [dataPeaks.w; dataValleys.w];
        % varargout{1}.w = tmp(sortInd);
        % tmp = [dataPeaks.p; dataValleys.p];
        % varargout{1}.p = tmp(sortInd);
    case 2
        varargout{1} = dataPeaks;
        varargout{2} = dataValleys;
end
end