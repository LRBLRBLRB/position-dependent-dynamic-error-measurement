function [velocitySegment, desiredValue, endIndex] = velocity_segmentation(v, adjacentParam, options)
%VELOCITY_SEGMENTATION Extract speed-varying segments for velocity
%
% Principles:
%   Seaarch the zero-locations of a velocity curve, and extract each segments
%   that start at the zero-locations, and end with horizontal lines

arguments
    v (:, 1)
    adjacentParam
    options.case {mustBeMember(options.case, {'Siemens', 'IDS'})} = 'IDS'
end

%% search for the starting locations for each segments
% only one zero-location can be kept before "zeroStart"
zeroStart = find(abs(v) > 1000, 1, 'first');

% only one zero-location can be kept after "zeroEnd"
zeroEnd = find(abs(v) > 1000, 1, 'last');

% zero-location sequence, to be the starting points of velocity segments
% (only keep those between zeroStart and zeroEnd)
zeroCrossings = find(v(1:end-1) .* v(2:end) <= 0);
indices = find(zeroCrossings < zeroStart);
zeroCrossings(indices(1:end - 1)) = [];
indices = find(zeroCrossings > zeroEnd);
zeroCrossings(indices(2:end)) = [];

% remove the adjacent zero-location
% tmp = zeroCrossings(2:end) - zeroCrossings(1:end - 1);
zeroCrossings = remove_adjacent(zeroCrossings, v, adjacentParam);
% zeroCrossings(tmp <= 0.2*sampleRate) = [];

% remove those which is small peak-valley
ind = ones(1, length(zeroCrossings));
for ii = 1:length(zeroCrossings)
    tmp = abs(v((zeroCrossings(ii) - adjacentParam / 2):(zeroCrossings(ii) + adjacentParam / 2))) < 50;
    if all(tmp)
        ind(ii) = 0;
    end
end
zeroCrossings(ind == 0) = [];

% additionally: for those which changes from 30000 to 5000, and do not cross the
% y=0 line
diffZeroCrossing1 = zeroCrossings(3) - zeroCrossings(2);
% diffZeroCrossing2 = zeroCrossings(end - 1) - zeroCrossings(end - 2);
% diffThreshold = diffZeroCrossing1 + diffZeroCrossing2 - 0.05*sampleRate;
diffThreshold = diffZeroCrossing1 * 1.1;
insertInd = find(diff(zeroCrossings(1:end - 1)) >= diffThreshold);

for ii = 1:length(insertInd)
    tmp = abs(v(zeroCrossings(insertInd(ii)):zeroCrossings(insertInd(ii) + 1)));
    insertValue = find(tmp >= 15000 & tmp <= 20000, 1, 'last');
    zeroCrossings = [zeroCrossings(1:insertInd(ii)); ...
        zeroCrossings(insertInd(ii)) + insertValue;...
        zeroCrossings(insertInd(ii) + 1:end)];
    insertInd = insertInd + 1;
end

% additionally: if the end point does not reach the v=0 line, then an extra
% point should be added in the end
if abs(v(end)) > 300
    zeroCrossings(end + 1) = length(v);
end

% debugging figure
% figure; plot(v); hold on; scatter(zeroCrossings, v(zeroCrossings));

%% search for the desired value & search for the ended location for each segments
desiredValue = zeros(length(zeroCrossings) - 1, 1);
changePoints = zeros(length(zeroCrossings) - 1, 1);
for ii = 1:length(zeroCrossings) - 1
    % seek for desired value
    if v(zeroCrossings(ii)) > 5000 % special cases one
        desiredValue(ii) = 5000;
    elseif v(zeroCrossings(ii)) < -5000 % special cases two
        desiredValue(ii) = -5000;
    else
        maxV = max(v(zeroCrossings(ii):zeroCrossings(ii + 1))); % abs = 30000
        minV = min(v(zeroCrossings(ii):zeroCrossings(ii + 1)));
        if maxV > 10000
            desiredValue(ii) = 30000;
        elseif maxV > 1000
            desiredValue(ii) = 5000;
        elseif minV < -10000
            desiredValue(ii) = -30000;
        else
            desiredValue(ii) = -5000;
        end
    end

    % ended location
    %   "min" is used to avoid that the measurement stops before the machine tool
    %   stops, where the zeroCrossings(end) will be the end point of velocity
    %   instead of the last zero location of velocity  
    tmp = min(zeroCrossings(ii) + find( ...
        abs(v(zeroCrossings(ii):zeroCrossings(ii + 1))) - abs(desiredValue(ii)) >= 0, ...
        1, 'last'), length(v));
    if isempty(tmp) 
        % if empty, that means the velocity cannot reach the desired value
        % then use the last point which reaches 90% of the point as the terminal
        desiredValue(ii) = NaN; % do not calculate the velocity parameters of this case
        % changePoints(ii) = zeroCrossings(ii) + find( ...
        %     abs(v(zeroCrossings(ii):zeroCrossings(ii + 1)) - v(zeroCrossings(ii))) ...
        %     >= 0.9*abs(v(zeroCrossings(ii)) - max(abs(v(zeroCrossings(ii):zeroCrossings(ii + 1))))), ...
        %     1, 'last');
        [~, changePoints(ii)] = max(abs(v(zeroCrossings(ii):zeroCrossings(ii + 1))));
        changePoints(ii) = zeroCrossings(ii) + changePoints(ii);
    else
        changePoints(ii) = tmp;
    end
    % scatter(changePoints(ii), v(changePoints(ii)), 'MarkerEdgeColor', [0.9290 0.6940 0.1250]);
end

% find the ending points of velocity segments
% tReverse = flip(t);
% [~, locs] = findpeaks(flip(v), t, "MinPeakHeight", 3000, "MaxPeakWidth", 2.5);
% changePoints1 = find(tReverse == locs(1));
% for ii = 1:length(locs) - 1
%     if locs(ii + 1) - locs(ii) > 0.1
%         changePoints1(end + 1) = find(tReverse == locs(ii));
%     end
% end
% changePoints1 = length(v) - changePoints1(:);
% 
% [~, locs] = findpeaks(flip(-1*v), t, "MinPeakHeight", 3000, "MaxPeakWidth", 2.5);
% changePoints2 = find(tReverse == locs(1));
% for ii = 1:length(locs) - 1
%     if locs(ii + 1) - locs(ii) > 0.1
%         changePoints2(end + 1) = find(tReverse == locs(ii));
%     end
% end
% changePoints2 = length(v) - changePoints2(:);
% 
% changePoints = sort([changePoints1;changePoints2]);

% diffV = abs(diff(v));
% threshold = mean(diffV) + 2 * std(diffV); % threshold of differences
% changePoints = find(diffV > threshold) + 1;

%% output
velocitySegment = [[zeroCrossings(1);changePoints(1:end - 1)], changePoints];
% velocitySegment = [zeroCrossings(1:end - 1), changePoints];
endIndex = zeroCrossings(end);
end