close all;
clear;
clc;
cd(fileparts(mfilename('fullpath')));
% addpath(genpath('../..'));

set(groot, 'DefaultAxesFontName', 'Times New Roman', 'DefaultAxesFontSize', 12);
set(groot, 'DefaultTextFontName', 'Times New Roman', 'DefaultTextFontSize', 12);
set(groot, 'DefaultAxesXMinorTick', 'on');

% Load and preprocess the axial data
FILE_PATH_A = char(['D:\OneDrive - sjtu.edu.cn\Research\Projects\202309_动态误差' ...
    '\202312_镜像铣平动轴动态误差测试\实验结果汇总\实验结果-双五轴长行程平动轴高速运动及换向动态精度测试-v2-Y轴A测点.xlsx']);
FILE_PATH_B = char(['D:\OneDrive - sjtu.edu.cn\Research\Projects\202309_动态误差' ...
    '\202312_镜像铣平动轴动态误差测试\实验结果汇总\实验结果-双五轴长行程平动轴高速运动及换向动态精度测试-v2-Y轴B测点.xlsx']);

% load Excel Worksheets
YAData = load_test_sheet(FILE_PATH_A);
YBData = load_test_sheet(FILE_PATH_B);

% delete the data with the value of 【光栅尺】
YAData(YAData.measureDevice == "光栅尺1", :) = [];
YAData(YAData.measureDevice == "光栅尺2", :) = [];
YBData(YBData.measureDevice == "光栅尺1", :) = [];
YBData(YBData.measureDevice == "光栅尺2", :) = [];

% Change the char type direction to logical type
YAData.direction  = cellfun(@(x) double(strcmp(x, '+')), YAData.direction);
YBData.direction  = cellfun(@(x) double(strcmp(x, '+')), YBData.direction);

% Recalculate the time properties
for ii = length(YAData.index2_disp_peak_moment):-1:1
    if YAData.index2_disp_peak_moment(ii) == 0
        YAData.index2_disp_peak_moment(ii) = NaN;
    else
        YAData.index2_disp_peak_moment(ii) = YAData.index2_disp_peak_moment(ii) - ...
            YAData.index2_disp_peak_moment(ii - 1);
        YBData.index2_disp_peak_moment(ii) = YBData.index2_disp_peak_moment(ii) - ...
            YBData.index2_disp_peak_moment(ii - 1);
    end
end

% 长度单位从mm改为um
YAData.index1_disp_peak = 1000 .* YAData.index1_disp_peak;
YBData.index1_disp_peak = 1000 .* YBData.index1_disp_peak;

% 加速度加绝对值
YAData.index7_accel_peak = abs(YAData.index7_accel_peak);
YBData.index7_accel_peak = abs(YBData.index7_accel_peak);

% 改变顺序，把换向方向不同其他自变量相同的组放在一起
numAData = height(YAData);
if numAData ~= height(YBData) || isinteger(numAData / 2)
    error('The number of rows between the two table is different');
else
    tmp = YAData;
    tmp(1:2:numAData, :) = YAData(1:numAData / 2, :);
    tmp(2:2:numAData, :) = YAData(numAData / 2 + 1:numAData, :);
    YAData = tmp;
    tmp = YBData;
    tmp(1:2:numAData, :) = YBData(1:numAData / 2, :);
    tmp(2:2:numAData, :) = YBData(numAData / 2 + 1:numAData, :);
    YBData = tmp;
end

% Combine the two tables
YBData.Properties.RowNames = cellstr(num2str(str2double(YBData.Properties.RowNames) ...
    + str2double(YAData.Properties.RowNames{end})));
YData = vertcat(YAData, YBData);
YData.measurePt(contains(YData.measurePt, 'A')) = {1};
YData.measurePt(contains(YData.measurePt, 'B')) = {2};
YData.measurePt = str2double(YData.measurePt);
YBData.Properties.RowNames = cellstr(num2str(str2double(YBData.Properties.RowNames) ...
    - str2double(YAData.Properties.RowNames{end})));
numData = height(YData);

% find the factor and response cloumns in the table
propNames = YData.Properties.VariableNames;
factorColumn = 2:7;
responseColumn = [];
for ii = 1:length(propNames)
    % if startsWith(propNames{ii}, 'index')
    %     factorIndex = [factorIndex, ii];
    % end
    if startsWith(propNames{ii}, 'index')
        responseColumn = [responseColumn, ii];
    end
end

%% 统计分析
% X = [ones(size(YData, 1), 1), YData{:, factorColumn}]; % 添加常数项到数据矩阵
% ano_p = cell(1,length(responseColumn));
% ano_tbl = cell(1,length(responseColumn));
% ano_stats = cell(1,length(responseColumn));
% for r = 1:length(responseColumn)
%     % ---------------- 正态性检验 ----------------
%     currentResponse = YData{:, responseColumn(r)};
%     validRow = ~isnan(currentResponse);
%     validResponse = currentResponse(validRow);
%     % 数据的Kolmogorov-Smirnov检验
%     % [h, p] = kstest((validResponse - mean(validResponse)) / std(validResponse));
%     % 残差的Kolmogorov-Smirnov检验
%     X1 = X;
%     X1(isnan(currentResponse), :) = [];
%     b = X1 \ validResponse; % 拟合线性模型
%     predictedResponse = X1 * b; % 预测值
%     residuals = validResponse - predictedResponse;% 计算残差
%     [h, p] = kstest((residuals - mean(residuals)) / std(residuals));
% 
%     if h == 0
%         disp(['Response_', num2str(r), ' 的残差通过正态性检验（p = ', num2str(p), '）。']);
%     else
%         disp(['Response_', num2str(r), ' 的残差未通过正态性检验（p = ', num2str(p), '）。']);
%     end
% 
%     % 残差的直方图和QQ图
%     figure;
%     subplot(1, 2, 1);
%     histogram(residuals, 10);
%     title(['Residuals Histogram (Response_', num2str(r), ')']);
%     xlabel('Residuals');
%     ylabel('Frequency');
% 
%     subplot(1, 2, 2);
%     qqplot(residuals);
%     title(['QQ Plot of Residuals (Response_', num2str(r), ')']);
% 
%     % ---------------- 极差分析 ----------------
% 
%     % ---------------- 方差分析 ----------------
%     validFactors = mat2cell(YData{validRow, factorColumn}, sum(validRow), ones(1, length(factorColumn)));
%     % ano = anova(validFactors, validResponse, "FactorNames", propNames(factorColumn), ...
%     %     "ResponseName", propNames(responseColumn));
%     [ano_p{r}, ano_tbl{r}, ano_stats{r}] = anovan(validResponse, validFactors, ...
%         'model', 'interaction', 'varnames', propNames(factorColumn), 'display', 'off');
% 
%     % 回归分析
% 
% end
% 
% return;

%% 比较正向与反向（后续分析都以这个为基础）
% compareCol = {'index1_disp_peak', 'index4_velo_peak', 'index7_accel_peak'}; % 比较的指标
compareCol = YData.Properties.VariableNames(8:16);
diffA = compare_property(YAData, 'useless', compareCol);
diffB = compare_property(YBData, 'useless', compareCol);
num0 = size(YAData, 1);
len = length(compareCol);
ylimVector = zeros(0, 2);
% 为方便分析，首先将正向、反向贴在一块
for jj = 1:len
    index = YData.(compareCol{jj});
    fig = figure('Name', sprintf('Direction comparison: %s', compareCol{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 2 * pos(3), pos(4)]);
    t1 = tiledlayout(3, 1);
    n1 = nexttile(1, [2, 1]);
    b = bar(1:numData / 2, [YData.(compareCol{jj})(YData.direction == 1), ...
            YData.(compareCol{jj})(YData.direction == 0)], 'grouped');
    yUnit = draw_bar(compareCol{jj}, b);
    ylabel(['Index ', yUnit]);
    draw_bar(compareCol{jj}, b);
    ylimVector(jj, :) = get(n1, 'YLim');
    n2 = nexttile(3, [1, 1]);
    bar(1:numData / 2, [diffA.(compareCol{jj}); diffB.(compareCol{jj})], ...
        'EdgeColor', 'none');
    xlabel('Group No.');
    ylabel(['\Delta', yUnit]);
    n2yLim = get(n2, "YLim");
    linkaxes([n1, n2], 'x');
    title(t1, sprintf('Direction comparison: %s', compareCol{jj}), 'FontName', 'Times New Roman', 'interpreter', 'none');
end

%% 比较不同测点
[~, measurePtUniqueValue, measurePtIndA] = compare_property(YData, 'measurePt', compareCol);
uniqueLen = length(measurePtUniqueValue);
barX = 1:(numData / uniqueLen / 2);
for jj = 1:len
    index = YData.(compareCol{jj});
    fig = figure('Name', sprintf('Measurement pt comparison: %s', compareCol{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
    t1 = tiledlayout(1, uniqueLen);
    nt = [];
    % 对于第jj个指标，画其在所有加速度取值下的图
    for kk = 1:uniqueLen
        nt(kk) = nexttile(t1, kk, [1, 1]);
        tmp = YData(measurePtIndA == kk, :);
        b = bar(barX + (jj - 1) * length(barX), ...
            [tmp.(compareCol{jj})(tmp.direction == 1), ...
            tmp.(compareCol{jj})(tmp.direction == 0)], 'grouped');
        yUnit = draw_bar(compareCol{jj}, b);
        set(nt(kk), "YLim", ylimVector(jj, :));
        xlabel('Group No.');
        title(nt(kk), sprintf('($Pt = %d$)', measurePtUniqueValue(kk)), ...
            'FontName', 'Times New Roman', 'FontSize', 10, 'Interpreter', 'latex');
    end
    title(t1, sprintf('Measurement pt comparison: %s', compareCol{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
    linkaxes(nt, 'y');
    ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
end

%% 比较不同Y轴位置
[~, posUniqueValue, posIndA] = compare_property(YData, 'yPos', compareCol);
uniqueLen = length(posUniqueValue);
barX = 1:(numData / uniqueLen / 2);
for jj = 1:len
    index = YData.(compareCol{jj});
    fig = figure('Name', sprintf('Traversal position comparison: %s', compareCol{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
    t1 = tiledlayout(1, uniqueLen);
    nt = [];
    % 对于第jj个指标，画其在所有加速度取值下的图
    for kk = 1:uniqueLen
        nt(kk) = nexttile(t1, kk, [1, 1]);
        tmp = YData(posIndA == kk, :);
        b = bar(barX + (jj - 1) * length(barX), ...
            [tmp.(compareCol{jj})(tmp.direction == 1), ...
            tmp.(compareCol{jj})(tmp.direction == 0)], 'grouped');
        yUnit = draw_bar(compareCol{jj}, b);
        set(nt(kk), "YLim", ylimVector(jj, :));
        xlabel('Group No.');
        title(nt(kk), sprintf('($y = %d mm$)', posUniqueValue(kk)), ...
            'FontName', 'Times New Roman', 'FontSize', 10, 'Interpreter', 'latex');
    end
    title(t1, sprintf('Traversal position comparison: %s', compareCol{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
    linkaxes(nt, 'y');
    ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
end

%% 比较不同Y轴速度
[~, veloUniqueValue, veloIndA] = compare_property(YData, 'yVelo', compareCol);
uniqueLen = length(veloUniqueValue);
barX = 1:(numData / uniqueLen / 2);
for jj = 1:len
    index = YData.(compareCol{jj});
    fig = figure('Name', sprintf('Velocity comparison: %s', compareCol{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
    t1 = tiledlayout(1, uniqueLen);
    nt = [];
    % 对于第jj个指标，画其在所有加速度取值下的图
    for kk = 1:uniqueLen
        nt(kk) = nexttile(t1, kk, [1, 1]);
        tmp = YData(veloIndA == kk, :);
        b = bar(barX + (jj - 1) * length(barX), ...
            [tmp.(compareCol{jj})(tmp.direction == 1), ...
            tmp.(compareCol{jj})(tmp.direction == 0)], 'grouped');
        yUnit = draw_bar(compareCol{jj}, b);
        set(nt(kk), "YLim", ylimVector(jj, :));
        xlabel('Group No.');
        title(nt(kk), sprintf('($y = %d mm/min$)', veloUniqueValue(kk)), ...
            'FontName', 'Times New Roman', 'FontSize', 10, 'Interpreter', 'latex');
    end
    title(t1, sprintf('Velocity comparison: %s', compareCol{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
    linkaxes(nt, 'y');
    ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
end

%% 加速度
[~, accelUniqueValue, accelIndA] = compare_property(YData, 'yAccel', compareCol);
uniqueLen = length(accelUniqueValue);
barX = 1:(numData / uniqueLen / 2);
for jj = 1:len
    index = YData.(compareCol{jj});
    fig = figure('Name', sprintf('Acceleration comparison: %s', compareCol{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
    t1 = tiledlayout(1, uniqueLen);
    nt = [];
    % 对于第jj个指标，画其在所有加速度取值下的图
    for kk = 1:uniqueLen
        nt(kk) = nexttile(t1, kk, [1, 1]);
        tmp = YData(accelIndA == kk, :);
        b = bar(barX + (jj - 1) * length(barX), ...
            [tmp.(compareCol{jj})(tmp.direction == 1), ...
            tmp.(compareCol{jj})(tmp.direction == 0)], 'grouped');
        yUnit = draw_bar(compareCol{jj}, b);
        set(nt(kk), "YLim", ylimVector(jj, :));
        xlabel('Group No.');
        title(nt(kk), sprintf('($a = %d m/s^2$)', accelUniqueValue(kk)), ...
            'FontName', 'Times New Roman', 'FontSize', 10, 'Interpreter', 'latex');
    end
    title(t1, sprintf('Acceleration comparison: %s', compareCol{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
    linkaxes(nt, 'y');
    ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
end

%% 跃度
[~, jerkUniqueValue, jerkIndA] = compare_property(YData, 'yJerk', compareCol);
uniqueLen = length(jerkUniqueValue);
barX = 1:(numData / uniqueLen / 2);
for jj = 1:len
    index = YData.(compareCol{jj});
    fig = figure('Name', sprintf('Jerk comparison: %s', compareCol{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
    t1 = tiledlayout(1, uniqueLen);
    nt = [];
    % 对于第jj个指标，画其在所有加速度取值下的图
    for kk = 1:uniqueLen
        nt(kk) = nexttile(t1, kk, [1, 1]);
        tmp = YData(jerkIndA == kk, :);
        b = bar(barX + (jj - 1) * length(barX), ...
            [tmp.(compareCol{jj})(tmp.direction == 1), ...
            tmp.(compareCol{jj})(tmp.direction == 0)], 'grouped');
        yUnit = draw_bar(compareCol{jj}, b);
        set(nt(kk), "YLim", ylimVector(jj, :));
        xlabel('Group No.');
        title(nt(kk), sprintf('($j = %d m/s^3$)', jerkUniqueValue(kk)), ...
            'FontName', 'Times New Roman', 'FontSize', 10, 'Interpreter', 'latex');
    end
    title(t1, sprintf('Jerk comparison: %s', compareCol{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
    linkaxes(nt, 'y');
    ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
end

%% functions
function unit = draw_bar(name, b)
    if ~isempty(b)
        barColor = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980]};
        barAlpha = {0.3, 0.3};
        for ii = 1:length(b)
            b(ii).FaceColor = barColor{ii};
            b(ii).EdgeColor = barColor{ii};
            b(ii).FaceAlpha = barAlpha{ii};
            b(ii).LineWidth = 1;
        end
        legend({'+', '-'}, 'Location', 'south', 'Orientation', 'horizontal');
    end

    if contains(name, 'moment') || contains(name, 'time') || contains(name, 'interval')
        unit = '(s)';
    elseif contains(name, 'disp')
        unit = '({\mu}m)';
    elseif contains(name, 'velo')
        unit = '(mm/min)';
    else
        unit = '(m/s^2)';
    end
end

% load data from a sheet of a work table
function data = load_test_sheet(filePath)
    sheetGroup = sheetnames(filePath);
    sheetLast = sheetGroup(end);
    readOpts = detectImportOptions(filePath, "FileType", "spreadsheet", ...
        "TextType", "string", ...
        "Sheet", sheetLast, ...
        "ReadRowNames", true, "VariableDescriptionsRange", "2:2");
    data = readtable(filePath, readOpts);
end

% 
function sortedTable = rearrange_table(inputTable, columnName)
    if ~istable(inputTable)
        error('Input must be a table.');
    elseif ~ismember(columnName, inputTable.Properties.VariableNames)
        error('Column "%s" not found in the table.', columnName);
    end

    % 对表格按指定列的值分组
    [uniqueValues, ~, groupIndices] = unique(inputTable.(columnName), 'stable'); % 保持顺序
    sortedRows = [];

    % 遍历每个分组，提取对应的行索引并按顺序拼接
    for i = 1:numel(uniqueValues)
        groupRows = find(groupIndices == i);
        sortedRows = [sortedRows; groupRows]; % 索引合并
    end

    % 根据排序后的索引重排表格
    sortedTable = inputTable(sortedRows, :);
end

% compare the values of property "colCompare" among which their property "colEqual" are the same
function [result, equalGroupValue, equalGroupInd] = compare_property(T, colEqual, colCompare)
    % check whether the property names are valid
    if ~ismember(colEqual, T.Properties.VariableNames)
        error('列名 "%s" 不存在于表格中。', colEqual);
    end
    if ~all(ismember(colCompare, T.Properties.VariableNames))
        missingColumns = colCompare(~ismember(colCompare, T.Properties.VariableNames));
        error('以下列名不存在于表格中：%s。', strjoin(missingColumns, ', '));
    end

    % group the data that have the same value of property colEqual
    equalData = T.(colEqual);
    [equalGroupValue, ~, equalGroupInd] = unique(equalData);
    result = table();

    % traverse each groups
    for ii = 1:length(equalGroupValue)
        % data of the current group
        groupRows = equalGroupInd == ii;

        groupResult = table(equalGroupValue(ii), 'VariableNames', {colEqual});
        
        % traverse each properties for comparison
        for jj = 1:length(colCompare)
            colData = T.(colCompare{jj});
            groupData = colData(groupRows);
            colDiff = groupData(end) - groupData(1);
            groupResult.(colCompare{jj}) = colDiff;
        end
        result = [result; groupResult];
    end
end
