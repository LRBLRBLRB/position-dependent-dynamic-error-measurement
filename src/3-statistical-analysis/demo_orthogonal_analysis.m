% 步骤 1：定义正交表与试验设计
orthogonal_design = [
    1, 1, 1, 1, 1, 1, 1;
    1, 2, 2, 2, 2, 2, 2;
    1, 3, 3, 2, 2, 3, 3;
    2, 1, 2, 1, 2, 1, 3;
    2, 2, 3, 2, 1, 2, 1;
    2, 3, 1, 1, 2, 3, 2;
    1, 1, 3, 2, 1, 3, 2;
    1, 2, 1, 1, 2, 1, 3;
    1, 3, 2, 2, 1, 2, 1;
    2, 1, 1, 2, 2, 2, 1;
    2, 2, 2, 1, 1, 3, 3;
    2, 3, 3, 1, 2, 1, 2;
];
Y = [5.2, 6.1, 4.8, 7.3, 5.9, 6.5, 4.2, 5.7, 6.8, 7.1, 5.4, 6.0];

% 步骤 2：方差分析
factor_names = {'A', 'B', 'C', 'D', 'E', 'F', 'G'};
[~, tbl] = anovan(Y, orthogonal_design, 'Model', 'linear', 'VarNames', factor_names, 'Display', 'on');

% 步骤 3：极差分析
range_values = zeros(1, size(orthogonal_design, 2));
for i = 1:size(orthogonal_design, 2)
    levels_i = unique(orthogonal_design(:,i));
    means = arrayfun(@(x) mean(Y(orthogonal_design(:,i) == x)), levels_i);
    range_values(i) = max(means) - min(means);
end
[~, idx] = sort(range_values, 'descend');
disp('因素重要性排序：'), disp(factor_names(idx));

% 步骤 4：主效应图
figure;
for i = 1:length(factor_names)
    subplot(3, 3, i);
    levels_i = unique(orthogonal_design(:,i));
    means = arrayfun(@(x) mean(Y(orthogonal_design(:,i) == x)), levels_i);
    plot(levels_i, means, '-o', 'LineWidth', 1.5);
    title(factor_names{i}); grid on;
end