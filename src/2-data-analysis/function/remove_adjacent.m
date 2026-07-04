function x = remove_adjacent(x0, y0, threshold)
% REMOVE_ADJACENT 
%   x: 原始整数递增数组
%   y: 对应的权重值
%   threshold: 判断“接近”的阈值

x = [];

currentGroup = 1; % indices of the adjacent x0 group

for ii = 2:length(x0)
    if x0(ii) - x0(currentGroup(end)) <= threshold
        % push the current value into the group if it is closer enough to the former one
        currentGroup(end + 1) = ii;
    else
        % deal with the current group if the current value is far from the former one
        [~, maxInd] = max(abs(y0(x0(currentGroup) + 50) - y0(x0(currentGroup) - 50)));
        % [~, maxInd] = max(abs(y0(currentGroup)));
        x(end + 1) = x0(currentGroup(maxInd));

        % initialize a new group
        currentGroup = ii;
    end
end

% deal with the last group
[~, maxInd] = max(abs(y0(x0(currentGroup))));
x(end + 1) = x0(currentGroup(maxInd));

% keep the row/column type of the output vectors the same as the input ones 
if size(x0, 1) > 1
    x = reshape(x, [], 1);
else
    x = reshape(x, 1, []);
end
end
