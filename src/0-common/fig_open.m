function fig_open(currentFolderPath)
%FIG_OPEN Open all the figures in a folder
%   此处显示详细说明

arguments
    currentFolderPath = pwd
end

% 检查文件夹路径是否有效
if ~isfolder(currentFolderPath)
    error('The specified folder does not exist.');
end

% 获取当前文件夹中所有 .fig 文件的列表
figFiles = dir(fullfile(currentFolderPath, '*.fig'));

% 打开所有 .fig 文件
for i = 1:length(figFiles)
    figFile = fullfile(currentFolderPath, figFiles(i).name);
    openfig(figFile, 'visible');
end

% 获取当前文件夹中所有子文件夹的列表
subFolders = dir(currentFolderPath);
for i = 1:length(subFolders)
    % 排除 '.' 和 '..' 文件夹
    if subFolders(i).isdir && ~strcmp(subFolders(i).name, '.') && ~strcmp(subFolders(i).name, '..')
        % 递归调用函数处理子文件夹
        fig_open(fullfile(currentFolderPath, subFolders(i).name));
    end
end

end

