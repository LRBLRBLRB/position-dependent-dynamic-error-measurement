close all;
clear;
clc;
cd(fileparts(mfilename('fullpath')));
% addpath(genpath('../..'));

set(groot, 'DefaultAxesFontName', 'Times New Roman', 'DefaultAxesFontSize', 12);
set(groot, 'DefaultTextFontName', 'Times New Roman', 'DefaultTextFontSize', 12);
set(groot, 'DefaultAxesXMinorTick', 'on');

% Load and preprocess the axial data
numMeasurePt = 3;
FILE_PATH{1} = char(['D:\OneDrive - sjtu.edu.cn\Research\Projects\202309_动态误差' ...
    '\202312_镜像铣平动轴动态误差测试\实验结果-双五轴长行程平动轴高速运动及换向动态精度测试-X轴A测点.xlsx']);
FILE_PATH{2} = char(['D:\OneDrive - sjtu.edu.cn\Research\Projects\202309_动态误差' ...
    '\202312_镜像铣平动轴动态误差测试\实验结果-双五轴长行程平动轴高速运动及换向动态精度测试-X轴B测点.xlsx']);
% FILE_PATH{3} = char(['D:\OneDrive - sjtu.edu.cn\Research\Projects\202309_动态误差' ...
%     '\202312_镜像铣平动轴动态误差测试\实验结果-双五轴长行程平动轴高速运动及换向动态精度测试-X轴C测点.xlsx']);
FILE_PATH{3} = char(['D:\OneDrive - sjtu.edu.cn\Research\Projects\202309_动态误差' ...
    '\202312_镜像铣平动轴动态误差测试\实验结果-双五轴长行程平动轴高速运动及换向动态精度测试-X轴D测点.xlsx']);

XData = [];
for ii = 1:numMeasurePt
    % load Excel Worksheets
    XData = load_test_sheet(FILE_PATH{ii}, XData);
end

XData.measurePt(contains(XData.measurePt, 'A')) = {1};
XData.measurePt(contains(XData.measurePt, 'B')) = {2};
% XData.measurePt(contains(XData.measurePt, 'C')) = {3};
XData.measurePt(contains(XData.measurePt, 'D')) = {3};
XData.measurePt = str2double(XData.measurePt);

% delete the data with the value of 【光栅尺】
XData(XData.measureDevice == "光栅尺1", :) = [];
XData(XData.measureDevice == "光栅尺2", :) = [];

% Change the char type direction to logical type
XData.direction  = cellfun(@(x) double(strcmp(x, '+')), XData.direction);

% Recalculate the time properties
for ii = length(XData.index2_disp_peak_moment):-1:1
    if XData.index2_disp_peak_moment(ii) == 0
        XData.index2_disp_peak_moment(ii) = NaN;
    else
        XData.index2_disp_peak_moment(ii) = XData.index2_disp_peak_moment(ii) - ...
            XData.index2_disp_peak_moment(ii - 1);
    end
end

% 长度单位从mm改为um
XData.index1_disp_peak = 1000 .* XData.index1_disp_peak;

% 加速度加绝对值
XData.index7_accel_peak = abs(XData.index7_accel_peak);

% 位移时间间隔去除离群点
isOutTmp = XData.index3_disp_interval(2:2:height(XData)) ./ XData.index3_disp_interval(1:2:height(XData));
isOut = reshape(repmat(any([isOutTmp > 5, isOutTmp < 0.2], 2), 1, 2), [], 1);
% XData.index3_disp_interval(isOut) = NaN;

% 改变顺序，把换向方向不同其他自变量相同的组放在一起
numData = height(XData);
if fix(numData / 2) ~= (numData / 2)
    error('The number of rows between the two table is different');
else
    for ii = 1:numMeasurePt
        tmp = XData(XData.measurePt == ii, :);
        numTmp = height(tmp);
        newTmp = tmp;
        newTmp(1:2:numTmp, :) = tmp(1:numTmp / 2, :);
        newTmp(2:2:numTmp, :) = tmp(numTmp / 2 + 1:numTmp, :);
        XData(XData.measurePt == ii, :) = newTmp;
    end
end

% find the factor and response cloumns in the table
propNames = XData.Properties.VariableNames;
factorColumnIndex = 2:8;
responseColumn = [];
for ii = 1:length(propNames)
    % if startsWith(propNames{ii}, 'index')
    %     factorIndex = [factorIndex, ii];
    % end
    if startsWith(propNames{ii}, 'index')
        responseColumn = [responseColumn, ii];
    end
end

% 比较的指标
% compareCol = {'index1_disp_peak', 'index4_velo_peak', 'index7_accel_peak'};
compareColumnName = XData.Properties.VariableNames(9:17);

%% 统计分析
% X = [ones(size(XData, 1), 1), XData{:, factorColumn}]; % 添加常数项到数据矩阵
% ano_p = cell(1, length(responseColumn));
% ano_tbl = cell(1, length(responseColumn));
% ano_stats = cell(1, length(responseColumn));
% for r = 1:length(responseColumn)
%     % ---------------- 正态性检验 ----------------
%     currentResponse = XData{:, responseColumn(r)};
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
%     validFactors = mat2cell(XData{validRow, factorColumn}, sum(validRow), ones(1, length(factorColumn)));
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
diffXData = [];
for ii = 1:numMeasurePt
    tmp = compare_property(XData(XData.measurePt == ii, :), 'useless', compareColumnName);
    diffXData = vertcat(diffXData, tmp);
end
len = length(compareColumnName);
ylimVector = zeros(0, 2);
% 为方便分析，首先将正向、反向贴在一块
for jj = 1:len
    index = XData.(compareColumnName{jj});
    fig = figure('Name', sprintf('正反向比较：%s', compareColumnName{jj}));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 2 * pos(3), pos(4)]);
    t1 = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    n1 = nexttile(1, [2, 1]);
    b = bar(1:numData / 2, [XData.(compareColumnName{jj})(XData.direction == 1), ...
            XData.(compareColumnName{jj})(XData.direction == 0)], 'grouped');
    yUnit = draw_bar(compareColumnName{jj}, b, barEdgeAlpha={0.5, 0.5}, barFaceAlpha={1, 1});
    ylabel(['Index ', yUnit]);
    ylimVector(jj, :) = get(n1, 'YLim');
    n2 = nexttile(3, [1, 1]);
    bar(1:numData / 2, diffXData.(compareColumnName{jj}), 'EdgeColor', 'none');
    xlabel('Group No.');
    ylabel(['\Delta', yUnit]);
    n2yLim = get(n2, "YLim");
    linkaxes([n1, n2], 'x');
    title(t1, sprintf('Direction comparison: %s', compareColumnName{jj}), 'FontName', 'Times New Roman', 'interpreter', 'none');
end

%% X轴测点 (still have bugs below)
% traverse all the factors
% for ii = factorColumnIndex
%     % tmpColumn, duplicated from factorColumn except the concerned factor 'ii'
%     tmpColumn = factorColumnIndex;
%     tmpColumn(tmpColumn == ii) = [];
% 
%     % 对除了XData.Properties.VariableNames{ii}的其他所有因素分组
%     [groupNumber, groupFactor] = findgroups(XData(:, XData.Properties.VariableNames(tmpColumn)));
%     tmpColumnUnique = unique(XData(:, ii));
% 
%     % 找出
%     % sortrows(XData, groupFactor)
%     groupRow = splitapply(@(x) {x}, (1:height(XData))', groupNumber);
%     sortedData = [];
%     for jj = 1:length(groupRow)
%         rows = groupRow{jj};
%         tmp = nan(1, height(tmpColumnUnique));
%         tmp(XData(rows, :).measurePt) = rows;
%         sortedData = [sortedData; tmp];
%     end
% 
%     % 画图：对应第jj个指标
%     for jj = 1:len
%         currentColumn = XData.(compareColumnName{jj});
%         tmp = nan(size(sortedData));
%         integerIndex = ~isnan(sortedData);
%         tmp(integerIndex) = currentColumn(sortedData(integerIndex));
% 
%         fig = figure('Name', sprintf('不同测点比较'));
%         pos = get(fig, 'Position');
%         set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
%         t1 = tiledlayout(3, 1);
%         % 对于第jj个指标，画其在所有加速度取值下的图
%         nt = nexttile(1, [2, 1]);
%         b = bar(tmp, 'grouped');
%         yUnit = draw_bar(compareColumnName{jj}, b, ...
%             barFaceAlpha={0.3, 0.3, 0.3}, barEdgeAlpha={1, 1, 1});
%         ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
%         title(t1, sprintf('%s comparison: %s', XData.Properties.VariableNames{ii}, ...
%             compareColumnName{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
%         legend(num2str(table2array(tmpColumnUnique)), ...
%             'Location', 'south', 'Orientation', 'horizontal');
%     end
% end

%% 2 测点位置
% tmpColumn, duplicated from factorColumn except the concerned factor 'ii'
ii= 2;
tmpColumn = factorColumnIndex;
tmpColumn(tmpColumn == ii) = [];

% 对除了XData.Properties.VariableNames{ii}的其他所有因素分组
% groupNumber: 组编号，其第i个元素表示XData(i, :)对应组因素groupFactor中的行号（可以理解为XData(i, :)属于第groupNumber(i)组）
% groupNumber: 组因素，即各个组的因素取值情况（从小到大排序）
[groupNumber, groupFactor] = findgroups(XData(:, XData.Properties.VariableNames(tmpColumn)));
tmpColumnUnique = unique(XData(:, ii));

% 将数据XData划分为由groupNumber指定的若干组，并将函数应用到每组中。即将XData所有行的编号分组
groupRow = splitapply(@(x) {x}, (1:height(XData))', groupNumber);
sortedData = []; % 将groupRow转换为double数组形式
for jj = 1:length(groupRow)
    rows = groupRow{jj};
    sortedData = [sortedData; rows'];
end

% 画图表示每个组的取值
fig = figure('Name', '不同测点比较: 对应的因素取值');
pos = get(fig, 'Position');
set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
t = tiledlayout(width(groupFactor), 1, 'TileSpacing', 'none', 'Padding', 'compact');
nt = [];
for jj = 1:width(groupFactor)
    nt(jj) = nexttile;
    factorValue = groupFactor.(groupFactor.Properties.VariableNames{jj});
    uniqueFactorValue = unique(factorValue);
    factorColorMap = colormap(sky(length(uniqueFactorValue)));
    colorMap = dictionary(uniqueFactorValue, num2cell(factorColorMap(1:length(uniqueFactorValue), :), 2));
    for kk = 1:height(groupFactor)
        color = colorMap(factorValue(kk));
        patch([kk - 1, kk, kk, kk - 1], [0, 0, 1, 1], color{1}); % 'FaceAlpha', 0.75, 'EdgeColor', color{1});
        hold on;
    end
    set(gca, 'XTickLabel', [], 'YTick', []);
    ylabel(groupFactor.Properties.VariableNames{jj}, 'Rotation', 0);
end
linkaxes(nt, 'x');
set(gca, 'XTickLabelMode', 'auto', 'XLim', [0, height(groupFactor)]);
title(t, sprintf('%s comparison: factor table', XData.Properties.VariableNames{ii}), ...
    'FontName', 'Times New Roman');

% 画图：对应第jj个指标
for jj = 1:len
    currentColumn = XData.(compareColumnName{jj});
    tmp = nan(size(sortedData));
    integerIndex = ~isnan(sortedData);
    tmp(integerIndex) = currentColumn(sortedData(integerIndex));

    fig = figure('Name', sprintf('不同测点比较'));
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), 3 * pos(3), pos(4)]);
    t1 = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    % 对于第jj个指标，画其在所有加速度取值下的图
    n1 = nexttile(1, [2, 1]);
    b = bar(tmp, 'grouped');
    yUnit = draw_bar(compareColumnName{jj}, b, ...
        barFaceAlpha={0.3, 0.3, 0.3}, barEdgeAlpha={1, 1, 1});
    ylabel(t1, ['Index ', yUnit], 'FontName', 'Times New Roman', 'Interpreter', 'none');
    title(t1, sprintf('%s comparison: %s', XData.Properties.VariableNames{ii}, ...
        compareColumnName{jj}), 'FontName', 'Times New Roman', 'Interpreter', 'none');
    lgd = legend(num2str(table2array(tmpColumnUnique)), ...
        'Location', 'south', 'Orientation', 'horizontal');
    title(lgd, XData.Properties.VariableNames{ii});
end

%% functions
function unit = draw_bar(name, b, options)
    arguments
        name 
        b = []
        options.barFaceColor = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]}
        options.barEdgeColor = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]}
        options.barFaceAlpha = {0.3, 0.3, 0.3}
        options.barEdgeAlpha = {1, 1, 1}
    end
    if ~isempty(b)
        for ii = 1:length(b)
            b(ii).FaceColor = options.barFaceColor{ii};
            b(ii).EdgeColor = options.barEdgeColor{ii};
            b(ii).FaceAlpha = options.barFaceAlpha{ii};
            b(ii).EdgeAlpha = options.barEdgeAlpha{ii};
            b(ii).LineWidth = 1;
        end
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
function data = load_test_sheet(filePath, data)
    arguments
        filePath 
        data  = []
    end
    sheetGroup = sheetnames(filePath);
    sheetLast = sheetGroup(end);
    readOpts = detectImportOptions(filePath, "FileType", "spreadsheet", ...
        "TextType", "string", ...
        "Sheet", sheetLast, ...
        "ReadRowNames", true, "VariableDescriptionsRange", "2:2");
    tmp = readtable(filePath, readOpts);
    if ~isempty(data)
        tmp.Properties.RowNames = cellstr(num2str(str2double(tmp.Properties.RowNames) ...
            + str2double(data.Properties.RowNames{end})));
    end
    data = vertcat(data, tmp);
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