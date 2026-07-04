% 按正交试验，系统地分析X轴运动过程中不同速度、加速度、跃度、滑枕位置对不同X轴Y轴测点的影响
% 正交实验的分析方法主要包括极差分析和重复实验的方差分析两种。
% 本课题，涉及的正交实验包括：有/无交互作用的多因素正交重复试验。特点包括：
%   - 存在多个评价标准（位移、速度、加速度的多重指标）
%   - 含有重复试验，每个指标重复了三次（但有的组只重复两次，看看这种情况还能否进行方差分析，如果不能就只做极差分析就好）
%   - 正交试验和遍历试验同时存在：某些变量如测点位置、X轴换向位置、速度、正反向等采用了遍历试验，而滑枕位置、加速度和跃度按正交试验设计
%   - 可能含有交互作用
%
% 分析方法：极差分析
%   

close all;
clear;
clc;
cd(fileparts(mfilename('fullpath')));

set(0, 'DefaultAxesFontName', 'Helvetica');
set(0, 'DefaultTextFontName', 'Helvetica');

% set(0, 'DefaultFigureVisible', 'off');

approach = 4;

%% 正交试验设计
% 因素A只有2水平，因素BC有3水平，因素DE有2水平，因素F有3水平的情况。但是，DEF虽然都有多个水平，
% 但是一次试验就能全部完成；而因素ABC每一个组合都需要跑一次新的试验。
% A：速度，2水平（5000 30000）
% B：加速度，3水平（1 2 3）
% C：跃度，3水平（40 80 140）
% D：方向，二水平（1 -1）
% E：测点，二水平（1 2）
% F：Y轴换向位置，三水平（0 -1500 -3000）
varValue(:, 1) = [5000; 30000; NaN];
varValue(:, 2) = [1; 2; 3];
varValue(:, 3) = [40; 80; 140];
varValue(:, 4) = [1; -1; NaN];
varValue(:, 5) = [1; 2; NaN];
varValue(:, 6) = [0; -1500; -3000];
CATEGORICAL_VAR = [4, 5];

nVars = size(varValue, 2);

switch approach
    case 1
        % 方案：所有变量一起做正交：L18.3.6 -> L18.2.3.3.3
        factorsLevel = [1	1	1	1	1	1;
                        1	1	2	2	3	3;
                        1	2	1	3	3	2;
                        1	2	3	1	2	3;
                        1	3	2	3	2	1;
                        1	3	3	2	1	2;
                        2	1	1	3	2	3;
                        2	1	3	1	3	2;
                        2	2	2	2	2	2;
                        2	2	3	3	1	1;
                        2	3	1	2	3	1;
                        2	3	2	1	1	3;
                        3	1	2	3	1	2;
                        3	1	3	2	2	1;
                        3	2	1	2	1	3;
                        3	2	2	1	3	1;
                        3	3	1	1	2	2;
                        3	3	3	3	3	3];
        factorsLevel(factorsLevel(:, 1) == 3, 1) = 2;
        factorsLevel(factorsLevel(:, 4) == 3, 4) = 2;
        factorsLevel(factorsLevel(:, 5) == 3, 5) = 2;
    case 2
        % 方案：ABC正交表L9.3.4 -> L9.2.1.3.2，DEF遍历
        levelABC = [1 1 1;
                    1 2 3;
                    1 3 2;
                    2 1 3;
                    2 2 2;
                    2 3 1;
                    1 1 2;
                    1 2 1;
                    2 3 3];
        levelsDEF = fullfact([2, 2, 3]); % 12x3矩阵，列对应D, E, F

        factorsLevel = [];
        for ii = 1:size(levelABC, 1)
            abc = levelABC(ii, :);
            combined = [repmat(abc, size(levelsDEF, 1), 1), levelsDEF];
            factorsLevel = [factorsLevel; combined];
        end
    case 3
        % 方案：ABC均匀表 LHS6 -> U12，DEF遍历
        % design = lhsdesign(6, 3, 'criterion', 'maximin');
        % levelABC = zeros(6, 3);
        % levelABC(:, 1) = discretize(design(:, 1), [0, 0.5, 1]); % A因素：2水平
        % levelABC(:, 2) = discretize(design(:, 2), [0, 1/3, 2/3, 1]); % B因素：3水平
        % levelABC(:, 3) = discretize(design(:, 3), [0, 1/3, 2/3, 1]); % C因素：3水平
        levelABC = [1, 1, 1;
                    1, 2, 3;
                    1, 3, 2;
                    2, 1, 3;
                    2, 2, 1;
                    2, 3, 2];
        levelsDEF = fullfact([2, 2, 3]); % 12x3矩阵，列对应D, E, F

        factorsLevel = [];
        for ii = 1:size(levelABC, 1)
            abc = levelABC(ii, :);
            combined = [repmat(abc, size(levelsDEF, 1), 1), levelsDEF];
            factorsLevel = [factorsLevel; combined];
        end
    case 4
        % 完全因子
        factorsLevel = fullfact([2, 3, 3, 2, 2, 3]);
end

factorsValue = factorsLevel;
for ii = 1:nVars
    tmpInd = factorsLevel(:, ii);
    tmpValue = varValue(:, ii);
    factorsValue(:, ii) = tmpValue(tmpInd);
end

% change [4, 5] fields to categorical
% factorsTable = table;
% factorsTable.velo = factorsValue(:, 1);
% factorsTable.accel = factorsValue(:, 2);
% factorsTable.jerk = factorsValue(:, 3);
% factorsTable.direction = categorical(factorsValue(:, 4), [-1, 1], {'Backward', 'Forward'});
% factorsTable.measure_pt = categorical(factorsValue(:, 5), [1, 2], ['A', 'B']);
% factorsTable.loc = factorsValue(:, 6);

%% 测量值导入
% 需要对照factors，找到Excel表格中对应行的所有九个指标并分别填入
rawTable = readtable("MATLAB_ANOVA_Y.xlsx", 'ReadRowNames', true);
columnOrder = rawTable.Properties.VariableNames;
columnOrder(1:nVars) = sort(columnOrder(1:nVars));
rawTable = rawTable(:, columnOrder);
rawTable.III = [];
rawTable.IX = [];
rowOrder = nan(size(factorsLevel, 1), 1);
for ii = 1:size(factorsLevel, 1)
    ind = find(all(rawTable{:, 1:nVars} == factorsValue(ii, :), 2));
    if length(ind) ~= 1
        error('Cannot find corresponding row in the resulttable that identifies the factorsValue');
    end
    rowOrder(ii) = ind;
end
response = rawTable{rowOrder, 7:end};

resultTable = array2table([factorsValue, response]);
resultTable.Properties.VariableNames = rawTable.Properties.VariableNames;
resultTable.D = categorical(resultTable.D, [-1, 1], {'Backward', 'Forward'});
resultTable.E = categorical(resultTable.E, [1, 2], {'A', 'B'});
% writetable(resultTable, ['orthogonal_', datestr(now, 'yyyymmddTHHMMSS'), '.xlsx']);

resultTableRaw = resultTable;

% normalized variables
% resultTable.A = resultTable.A - mean(resultTable.A);
% resultTable.B = resultTable.B - mean(resultTable.B);
% resultTable.C = resultTable.C - mean(resultTable.C);
% resultTable.F = resultTable.F - mean(resultTable.F);
% normalized
resultTable.A = zscore(resultTable.A);
resultTable.B = zscore(resultTable.B);
resultTable.C = zscore(resultTable.C);
resultTable.F = zscore(resultTable.F);

% y>0
% resultTable.I = resultTable.I + 1 - min(resultTable.I);
% resultTable.VII = resultTable.VII + 1 - min(resultTable.VII);

%% 缺省值处理

% % 删除包含缺失值的行
% A_clean = rmmissing(A);
% B_clean = rmmissing(B);
% Y1_clean = rmmissing(Y1);
% 
% % 使用线性插值法填补缺失值
% Y1_filled = fillmissing(Y1, 'linear');

%% 单响应值分析
alpha = 0.05; % significance level of ANOVA
% different models
lrmLinear = cell(size(response, 2), 1);
lrmInter = cell(size(response, 2), 1);
lrmInterBoxcox = cell(size(response, 2), 1);
lrmStep = cell(size(response, 2), 1);
glrmInter = cell(size(response, 2), 1);
mdlCompareLinear = zeros(size(response, 2), 1);
mdlCompareInter = zeros(size(response, 2), 1);
multCompare = cell(size(response, 2), 10);
% anovaResults = struct("p", {}, "tbl", {}, "stats", {}, "terms", {});
anovas = cell(size(response, 2), 1);
% table('Size', [size(response, 2), 4], 'VariableTypes', {'double', 'cell', 'struct'}, ...
%     'VariableNames', ["p", "tbl", "stats", "terms"]);

filename = 'analysis-results';

for ii = 1:size(response, 2)
    fprintf('\n-------------------------- %d --------------------------\n', ii);

    % plot interaction situation
    figure('Name', 'Normalization test');
    figPos = get(gcf, "Position");
    set(gcf, "Position", [figPos(1), figPos(2) - figPos(4), figPos(3), figPos(4)]);
    subplot(2, 1, 1);histogram(response(:, ii), "Normalization", "pdf");
    subplot(2, 1, 2);histfit(response(:, ii), [], "normal")
    figure('Name', sprintf('%d Main-Effect', ii));
    figPos = get(gcf, "Position");
    set(gcf, "Position", [figPos(1) - figPos(3), figPos(2), figPos(3), figPos(4)]);
    maineffectsplot(response(:, ii), factorsValue, 'varnames', [resultTable.Properties.VariableNames(1:nVars)]);
    figure('Name', sprintf('%d Interaction', ii));
    figPos = get(gcf, "Position");
    set(gcf, "Position", [figPos(1) + figPos(3), figPos(2), figPos(3), figPos(4)]);
    interactionplot(response(:, ii), factorsValue, 'varnames', [resultTable.Properties.VariableNames(1:nVars)]);
    drawnow;

    % -------------------- Linear Regression --------------------
    % linear regression model
        % modelspec = 'constant', 'linear', 'interactions', 'purequadratic', 'quadratic', 'polyijk'(self-design)
    lrmLinear{ii} = fitlm(resultTable(:, [1:nVars, ii+nVars]), resultTable.Properties.VariableNames{ii+nVars}, ...
        'linear', 'RobustOpts', 'on', ...
        'CategoricalVars', [resultTable.Properties.VariableNames(CATEGORICAL_VAR)]);
    plot_lm(ii, lrmLinear{ii}, sprintf("%s.xls", filename), 1, alpha);

    % stepwise regression: stepwise modeling, starting from a constant model, adding or removing predictors forward/backward
    %    Criterion: 'sse' (default), 'aic', 'bic', 'rsquared', 'adjrsquared'
    %    PEnter:    0.05,           0,    0,    0.1,       0
    %    PRemove:   0.10,           0.01, 0.01, 0.05,      -0.05
    lrmStep{ii} = stepwiselm(resultTable(:, [1:nVars, ii+nVars]), resultTable.Properties.VariableNames{ii+nVars}, ...
        'linear', 'Lower', 'linear', ...
        'CategoricalVars', [resultTable.Properties.VariableNames(CATEGORICAL_VAR)], ...
        'Criterion', 'sse', 'PEnter', 0.05, 'PRemove', 0.10);
    plot_lm(ii, lrmStep{ii}, sprintf("%s.xls", filename), 2, alpha);

    % interaction regression model
    lrmInter{ii} = fitlm(resultTable(:, [1:nVars, ii+nVars]), resultTable.Properties.VariableNames{ii+nVars}, ...
        'interactions', 'RobustOpts', 'on', ...
        'CategoricalVars', [resultTable.Properties.VariableNames(CATEGORICAL_VAR)]);
    plot_lm(ii, lrmInter{ii}, sprintf("%s.xls", filename), 3, alpha);

    % 异方差性检验，若很差就要做BoxCox处理
    % X_design = [ones(height(resultTable), 1) factorsValue]; % 设计矩阵
    % [~, pValue] = het_breuschpagan(lrmInter{ii}.Residuals.Raw, X_design); % Breusch-Pagan检验
    % if pValue <= 0.05
    %     if min(response(:, ii)) <= 0
    %         y_transformed = response(:, ii) + 1 - min(response(:, ii)); % 确保最小值为1
    %     else
    %         y_transformed = response(:, ii);
    %     end
    %     [transformed_y, lambda] = boxcox(y_transformed);
    %     data_transformed = array2table([factorsValue, transformed_y]);
    %     data_transformed.Properties.VariableNames = resultTable.Properties.VariableNames([1:nVars, ii+nVars]);
    %     lrmInterBoxcox{ii} = fitlm(data_transformed, resultTable.Properties.VariableNames{ii+nVars}, ...
    %     'interactions', 'RobustOpts', 'on', ...
    %     'CategoricalVars', [resultTable.Properties.VariableNames(CATEGORICAL_VAR)]);
    %     plot_lm(ii, lrmInterBoxcox{ii}, sprintf("%s.xls", filename), 3, alpha);
    % end

    % similarity test
    % if ~isempty(lrmLinear{ii})
    %     LR_stat = 2*(lrmStep{ii}.LogLikelihood - lrmLinear{ii}.LogLikelihood);
    %     dof = lrmStep{ii}.NumCoefficients - lrmLinear{ii}.NumCoefficients;
    %     mdlCompareLinear(ii) = 1 - chi2cdf(LR_stat, dof);
    %     fprintf('Stepwise effectiveness: %s\n', categorical(mdlCompareLinear(ii) < alpha, [0, 1], {'×', '√'}));
    % end
    % if ~isempty(lrmInter{ii})
    %     LR_stat = 2*(lrmStep{ii}.LogLikelihood - lrmInter{ii}.LogLikelihood);
    %     dof = lrmStep{ii}.NumCoefficients - lrmInter{ii}.NumCoefficients;
    %     mdlCompareInter(ii) = 1 - chi2cdf(LR_stat, dof);
    %     fprintf('Stepwise precision: %s\n', categorical(mdlCompareInter(ii) < alpha, [0, 1], {'√', '×'}));
    % end
    %
    % post-hoc test
    % mdlStepR_anovaTbl = anova(mdlStepR{ii}, 'component');
    % mdlStepR_interaction = mdlStepR_anovaTbl( ...
    %     contains(mdlStepR_anovaTbl.Properties.RowNames, ':') ...
    %     & mdlStepR_anovaTbl.pValue < alpha, :);
    % mdlStepR_interactionSort = sortrows(mdlStepR_interaction, 'pValue', 'ascend');
    % figure;
    % tiledlayout(ceil(sqrt(height(mdlStepR_interaction))), ceil(sqrt(height(mdlStepR_interaction))));
    % for jj = 1:height(mdlStepR_interactionSort)
    %     tmpVars = strsplit(mdlStepR_interactionSort.Properties.RowNames{jj}, ':');
    %     multCompare{ii, jj} = multcompare(mdlStepR_anova, string(tmpVars), "CriticalValueType", "bonferroni");
    % end

    % -------------------- ANOVA --------------------
    % anovas{ii} = anova(resultTable(:, [1:nVars, ii+nVars]), resultTable.Properties.VariableNames{ii+nVars}, ...
    %     'FactorNames', [resultTable.Properties.VariableNames(1:nVars)], ...
    %     'CategoricalFactors', [resultTable.Properties.VariableNames(CATEGORICAL_VAR)], ...
    %     'ModelSpecification', string(mdlStepR{ii}.Formula));
    % anova_interaction = anovas{ii}.stats( ...
    %     contains(anovas{ii}.ExpandedFactorNames, ':') ...
    %     & anovas{ii}.Coefficients < alpha, :);
    % anova_interactionSort = sortrows(anova_interaction, 'pValue', 'ascend');
    % for jj = 1:height(mdlStepR_interactionSort)
    %     tmpVars = strsplit(mdlStepR_interactionSort.Properties.RowNames{jj}, ':');
    %     multCompare{ii, jj} = multcompare(anovas{ii}, string(tmpVars), "CriticalValueType", "bonferroni");
    % end
    %
    % anova analysis without creating anova objects
    % [anovaResults(ii).p, anovaResults(ii).tbl, anovaResults(ii).stats, anovaResults(ii).terms] = anovan( ...
    %     response(:, ii), factorsValue, ...
    %     'alpha', alpha, 'display', 'on', 'model', 'linear', ...
    %     'varnames', [rawTable.Properties.VariableNames(1:nVars)]);
    % figure('Name', sprintf('%d-4 ANOVAN', ii));
    % tl4 = tiledlayout(2, 2);
    % nexttile; histfit(anovaResults(ii).stats.resid);
    % nexttile; qqplot(anovaResults(ii).stats.resid);
    % disp(anovaResults(ii).p); % 输出P值，判断各因素的显著性
    %
    % ANOVA 合理性分析
    % 严格正态性：各组数据（模型残差）服从正态分布（小样本Shapiro-Wiki检验、大样本Kolmogorov-Smirnov检验、QQ图）
    % [~, p] = swtest(stats.resid); % residuals为模型残差
    % if p < alpha, disp('拒绝正态性假设'); else, disp('数据服从正态分布'); end
    % 
    % 方差齐性检验：各组数据方差相等（Levene检验、正太数据的Bartlett检验、残差图）
    % groups = cell(size(factorsValue, 1), 1);
    % for i = 1:size(factorsValue, 1)
    %     groups{i} = sprintf('Group%d', i);
    % end
    % vartestn(response(:, ii), groups)
    % figure;
    % plot(anovaStats{ii}.resid, 'o');
    % hold on;
    % yline(0, '--r');
    % title('残差图检验方差齐性');
    % xlabel('试验序号');
    % ylabel('残差');
    % figure;
    % plot(stats.yhat, residuals, 'o');
    % hold on;
    % yline(0, '--r');
    % xlabel('预测值');
    % ylabel('残差');
    % title('残差vs预测值');
    %
    % 独立性检验：Durbin-Watson检验
    % [~, p] = dwtest(anovaResults(ii).stats.resid, factorsValue);
    % if p < alpha
    %     disp('存在自相关，独立性假设不满足');
    % end

    % -------------------- Generalized Linear Regression --------------------
    % glrmInter{ii} = fitglm(resultTable(:, [1:nVars, ii+nVars]), resultTable.Properties.VariableNames{ii+nVars}, ...
    %     'interactions', 'Distribution', 'normal', 'Link', 'identity', 'Intercept', true, ...
    %     'CategoricalVars', [resultTable.Properties.VariableNames(CATEGORICAL_VAR)]);
    % plot_lm(ii, glrmInter{ii}, sprintf("%s.xls", filename), 4, alpha);

    % -------------------- Machine learning --------------------

    drawnow;
    % pause;
end

%% 多响应变量的综合分析
% 由于你有7个响应变量，可以采用加权平均法或其他多响应变量的综合方法对多个响应变量进行分析。例如，可以对每个响应变量的结果进行
% 标准化处理，然后加权求和，得到每个因素对多个响应变量的综合影响。 

% 多因素方差分析
maov = manova(resultTable, ["I", "II", "IV", "V", "VI", "VII", "VIII"], ...
    FactorNames=["A", "B", "C", "D", "E", "F"], CategoricalFactors=CATEGORICAL_VAR);
disp(maov);
% figure('Name', 'MANOVA');
% manovacluster(maov.stats);
drawnow;

% fig_save("analysis-results-fig");
% fig_tiled;

%% 贡献率分析

% sstotal = sum((Y1 - mean(Y1)).^2);  % 总方差
% ssfactor_A = sum((mean(Y1(A == 1)) - mean(Y1)).^2);  % 因素A的平方和
% 
% contribution_A = ssfactor_A/sstotal;  % A的方差贡献率
% fprintf('因素A对响应变量1的贡献率为 %.2f%%\n', contribution_A*100);

save(sprintf("%s.mat", filename), "resultTable", "lrmLinear", "lrmStep", "lrmInter");

%% function to plot the result of linear regression
function plot_lm(ii, model, filename, id, alpha)
    switch id
        case 1
            sheetName = 'LinearRobust';
        case 2
            sheetName = 'Stepwise';
        case 3
            sheetName = 'Interaction';
        case 4
            sheetName = 'GeneralInteraction';
    end

    figure('Name', sprintf('%d-%d %s Residuals', ii, id, sheetName));
    tiledlayout(2, 2, "TileSpacing", "tight", "Padding", "tight");
    nexttile; plotResiduals(model, 'histogram'); % residual histogram
    nexttile; plotResiduals(model, 'probability'); % QQ plot
    nexttile; plotResiduals(model, 'fitted'); % residual-fitted
    nexttile; if id <= 3, plotEffects(model); % main effects of LM
    else, plotDiagnostics(model, 'leverage'); end % identify high leverage observations of GLM
    % nexttile; plotResiduals(model, 'lagged');

    disp(model.Formula);
    % disp(model);
    % disp(model.anova);
    % anova_table = model.anova;
    % sig_interactions = anova_table(contains(anova_table.Properties.RowNames, ':') & anova_table.pValue < alpha, :);
    % disp('显著交互作用：');
    % disp(sig_interactions);

    if ~exist(filename, 'file')
        tableHeight = height(model.Coefficients) + 1;
        writetable(model.Coefficients, filename, ...
            'Sheet', sprintf('%s-Coefficients', sheetName), ...
            'Range', sprintf('A%d:H%d', 1 + (ii - 1)*30, tableHeight + (ii - 1)*30), 'WriteRowNames', true);
        if id <= 3
            writetable(model.anova, filename, ...
                'Sheet', sprintf('%s-ANOVA', sheetName), ...
                'Range', sprintf('A%d:H%d', 1 + (ii - 1)*30, tableHeight + (ii - 1)*30), 'WriteRowNames', true);
            % writetable(models{ii}.Residuals, filename, 'Sheet', 'LinearRobust-Residuals', ...
            %     'Range', sprintf('A%d:E%d', 1 + (ii - 1)*10, 8 + (ii - 1)*10), 'WriteRowNames', true);
            tmpTable = table(model.Rsquared.Ordinary, model.Rsquared.Adjusted, ...
                model.ModelFitVsNullModel.Fstat, model.ModelFitVsNullModel.Pvalue, ...
                'VariableNames', {'R2', 'Adj_R2', 'Fstat', 'PValue'});
            writetable(tmpTable, filename, ...
                'Sheet', sprintf('%s-ModelMetrics', sheetName), ...
                'Range', sprintf('A%d:E%d', 1 + (ii - 1)*3, tableHeight + (ii - 1)*3));
        end
    end
end

% Breusch-Pagan检验
function [stat, pValue] = het_breuschpagan(residuals, X)
    % 计算残差平方
    residuals_sq = residuals.^2;
    % 回归残差平方对设计矩阵
    model_bp = fitlm(X, residuals_sq, 'Intercept', false);
    % 计算统计量
    stat = 0.5 * model_bp.SSR;
    % 卡方检验
    df = size(X, 2) - 1; % 去除截距后的变量数
    pValue = 1 - chi2cdf(stat, df);
end

% 分类变量之间的交互：计算不同B水平下A的效应
function interaction_analysis_cat_cat(data)
B_levels = categories(data.B);
for i = 1:length(B_levels)
fprintf('=== 在B=%s的水平下分析A的效应 ===\n', B_levels{i});
% 子数据集：固定B的水平
sub_data = data(data.B == B_levels{i}, :);
% 拟合子模型（仅包含A的主效应）
sub_model = fitglm(sub_data, 'Y ~ A', 'Distribution', 'binomial');
% 提取A的效应（例如实验组 vs 对照组的OR值）
coef = sub_model.Coefficients.Estimate;
or = exp(coef(2)); % A=1 vs A=0的比值比
p_value = sub_model.Coefficients.pValue(2);
fprintf('A的效应（OR=%.2f, p=%.4f）\n', or, p_value);
end
end
% 分类变量与连续变量的交互（A为分类，X为连续），计算不同A水平下X的简单斜率
function interaction_analysis_cat_con(data)
% 分离不同A水平的数据
A_levels = categories(data.A);
for i = 1:length(A_levels)
fprintf('=== 在A=%s的水平下分析X的效应 ===\n', A_levels{i});
% 子数据集：固定A的水平
sub_data = data(data.A == A_levels{i}, :);
% 拟合子模型（仅包含X的主效应）
sub_model = fitglm(sub_data, 'Y ~ X', 'Distribution', 'binomial');
% 提取X的效应（斜率）
coef = sub_model.Coefficients.Estimate;
slope = coef(2); % X的系数
p_value = sub_model.Coefficients.pValue(2);
fprintf('X的斜率=%.2f (p=%.4f)\n', slope, p_value);
end
end
