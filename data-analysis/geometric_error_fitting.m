% fit the geometric error of the corresponding axis, and export the error map for further use

clear;
clc;

% change the directory of matlab to the folder of the current m file
currentFilePath = mfilename("fullpath");
currentFolder = fileparts(currentFilePath);
[~, lastFolder, ~] = fileparts(currentFolder);
if ~strcmp(lastFolder, "data-analysis")
    cd 'D:\Code\2023-12_MachineToolError\mirror-milling-error\data-analysis';
else
    cd(currentFolder);
end

%% Load the original lineear measurement results
geometricFilePath = "D:\WorkingDir\Experiments\202406-mms-dynamics\xl80 results\X positioning error.xlsx";
% geometricFilePath = "D:\WorkingDir\Experiments\202406-mms-dynamics\xl80 results\End positioning error along X.xlsx";

dataOriginal = readtable(geometricFilePath, "VariableNamingRule", "preserve");
dataOriginal = renamevars(dataOriginal, ["次", "方向", "目标测点", "目标值（毫米）", "实际读数（毫米）", "误差（毫米）"], ...
    ["Round", "DirectionChar", "Target", "TargetValue", "ActualValue", "Error"]);
Direction = nan(size(dataOriginal, 1), 1);
Direction(strcmp(dataOriginal.DirectionChar, '(+)')) = 1;
Direction(strcmp(dataOriginal.DirectionChar, '(-)')) = 0;
if any(isnan(Direction))
    error('There exists direction characters that cannot be recognized.');
end
dataOriginal = addvars(dataOriginal, Direction, 'Before', "DirectionChar");
clear Direction;
% T = removevars(T, "DirectionChar");
% only "Direction", "Target", and "Error" are used below

%% Organize the original data
% calculate the average value of each target point

% find out the target list
tmpTable = dataOriginal(dataOriginal.Round == 1, :);
targetList = tmpTable.TargetValue;
targetNum = length(targetList);

dataAverage = table([], [], [], 'VariableNames', ["TargetValue", "Direction", "Error"]);
% calculate the average error of each target when the axis travels along the negative/positive direction
for jj = 0:1
    tmpTable = dataOriginal(dataOriginal.Direction == jj, :);
    averageError = nan(targetNum, 1);
    for ii = 1:targetNum
        % calculate the average data at each target
        tmp = tmpTable(tmpTable.TargetValue == targetList(ii), :); % table-formatted data at Target ii
        averageError(ii) = mean(tmp.Error);
    end

    % build a table to store the error map above
    newTables = table(targetList, jj * ones(targetNum, 1), averageError, ...
        'VariableNames', dataAverage.Properties.VariableNames);
    dataAverage = [dataAverage; newTables];
end

% for convenience, calculate the 
averageError = nan(targetNum, 1);
for ii = 1:targetNum
    tmp = dataAverage(dataAverage.TargetValue == targetList(ii), :);
    if range(tmp.Error) < 0.005
        averageError(ii) = mean(tmp.Error);
    else
        error("The deviation of positive and negative error is so large that they cannot be averaged.");
    end
end
dataAverageBidirection = table(targetList, averageError, 'VariableNames', ["TargetValue", "Error"]);

clear tmp tmpTable newTables targetList averageError 

%% Fit the geometric error
geometric_error_pp = makima(dataAverageBidirection.TargetValue, dataAverageBidirection.Error);

figure("Name", "几何误差");
geometric_error_x = min(dataAverageBidirection.TargetValue):0.001:max(dataAverageBidirection.TargetValue);
geometric_error_val = ppval(geometric_error_pp, geometric_error_x);
plot(geometric_error_x, geometric_error_val, "DisplayName", "fitting curve");
hold on;
scatter(table2array(dataAverage(dataAverage.Direction == 0, "TargetValue")), ...
    table2array(dataAverage(dataAverage.Direction == 0, "Error")), ...
    "filled", "DisplayName", "Negative error");
scatter(table2array(dataAverage(dataAverage.Direction == 1, "TargetValue")), ...
    table2array(dataAverage(dataAverage.Direction == 1, "Error")), ...
    "filled", "DisplayName", "Negative error");
legend("Location", "best");

%% Save the geometric error fitting results
[~, geometricFileName, ~] = fileparts(geometricFilePath);
geometricFileName = replace(geometricFileName, " ", "_");

% savefig(strcat(geometricFileName, ".fig"));
save(strcat(geometricFileName, ".mat"), "geometric_error_pp");

