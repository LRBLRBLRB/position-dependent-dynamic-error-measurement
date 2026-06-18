function varargout = accel_segmentation(t, a, theo_accel, options)
%ACCEL_SEGMENTATION Seperate acceleration-varying segments for the measaured signal,
%   and 
%
% Inputs: 
%   t           time sequence for the measured signal
%   a           acceleration sequence for the measured signal
%   theo_accel  theoretical acceleration for the corresponding test
%   options     options

arguments
    t (:, 1)
    a (:, 1)
    theo_accel double
    options.case {mustBeMember(options.case, {'Siemens', 'IDS'})} = 'IDS'
    options.MinPeakHeight = 0.5
    options.MinPeakProminence = 0.5
    options.MinPeakDistance = 1
    options.PlotName = "峰值位置"
end

% 使用findpeaks函数检测局部最大值（峰值）
[pks1, locs1, w1, p1] = findpeaks(a, t, ...
    'MinPeakProminence', theo_accel*0.3, ...
    'MinPeakDistance', options.MinPeakDistance, ...
    'MinPeakHeight', options.MinPeakHeight);

% 使用findpeaks函数检测局部最小值（谷值），对信号取负值
[pks2, locs2, w2, p2] = findpeaks(-1*a, t, ...
    'MinPeakProminence', theo_accel*0.3, ...
    'MinPeakDistance', options.MinPeakDistance, ...
    'MinPeakHeight', options.MinPeakHeight);

ind1 = zeros(size(locs1));
for ii = 1:length(locs1)
    ind1(ii) = find(t == locs1(ii));
end
ind2 = zeros(size(locs2));
for ii = 1:length(locs2)
    ind2(ii) = find(t == locs2(ii));
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
    dataPeaks(ii).class = round(dataPeaks(ii).pks / 100) * 100;
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
    dataValleys(ii).class = round(dataValleys(ii).pks / 100) * 100;
    dataValleys(ii).error = dataValleys(ii).pks - dataValleys(ii).class;
end
dataValleys = struct2table(dataValleys);

% dataValleys = struct('pks',-1*pks2,'locs',locs2,'w',w2,'p',-1*p2,'ind',ind2);
% dataValleys.class = round(dataValleys.pks / 100) * 100;
% dataValleys.error = dataValleys.pks - dataValleys.class;

plot_peaks(t,a,dataPeaks,dataValleys,"PlotName",options.PlotName);

switch nargout
    case 1
        % combine the datapeaks and dataValleys into one sequence
        varargout{1} = [dataPeaks;dataValleys];
        varargout{1} = sortrows(varargout{1},'locs');
        % [varargout{1}.locs,sortInd] = sort([dataPeaks.locs;dataValleys.locs]);
        % tmp = [dataPeaks.ind;dataValleys.ind];
        % varargout{1}.ind = tmp(sortInd);
        % tmp = [dataPeaks.pks;dataValleys.pks];
        % varargout{1}.pks = tmp(sortInd);
        % tmp = [dataPeaks.w;dataValleys.w];
        % varargout{1}.w = tmp(sortInd);
        % tmp = [dataPeaks.p;dataValleys.p];
        % varargout{1}.p = tmp(sortInd);
    case 2
        varargout{1} = dataPeaks;
        varargout{2} = dataValleys;
end
end