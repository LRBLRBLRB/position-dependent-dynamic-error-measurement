function fig_save(folderPath)
%FIG_SAVE 此处显示有关此函数的摘要
%   此处显示详细说明

figHandles = findall(groot, 'Type', 'figure'); % 查找所有图窗

for i = numel(figHandles):-1:1
    fig = figHandles(i);
    % 构建文件名
    filename = sprintf('%d %s', fig.Number, fig.Name);
    % 保存图窗
    filePath = fullfile(folderPath, filename);
    savefig(fig, filePath);
end

end