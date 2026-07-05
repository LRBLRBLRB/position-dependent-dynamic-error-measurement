%% 处理文件夹中XL-80导出的数据

clear; clc;
cd(fileparts(mfilename('fullpath')));
folderPath = 'D:\WorkingDir\Experiments\202406-mms-dynamics\xl80 results\20240528 xl80';

xl80Data = load_folder_xl80_data(folderPath);
%% 对比dyconxl导出选项

numGroup = size(xl80Data, 1);
fig1 = figure;
ax1 = axes(fig1);
colororder(fig1, 'gem12');
fig2 = figure;
t2 = tiledlayout(fig2, 4, 1);
colororder(fig2, 'gem12');
for ii = 1:numGroup
    [~, dispName, ~] = fileparts(xl80Data{ii, 1});
    plot(ax1, xl80Data{ii, 2}.Time, xl80Data{ii, 2}.Measurement, ...
        'DisplayName', dispName);
    hold(ax1, "on");
    legend(ax1, 'Location', 'best');
    ax2 = nexttile(t2);
    plot(ax2, xl80Data{ii, 2}.Time, xl80Data{ii, 2}.Measurement, ...
        'DisplayName', dispName);
    legend(ax2);
    drawnow;
    % pause();
end
fig3 = figure;
[~, dispName, ~] = fileparts(xl80Data{2, 1});
plot(xl80Data{2, 2}.Time, ...
    xl80Data{2, 2}.Measurement - xl80Data{4, 2}.Measurement, ...
        'DisplayName', dispName, 'LineWidth', 1.5);
hold("on");
[~, dispName, ~] = fileparts(xl80Data{3, 1});
plot(xl80Data{3, 2}.Time, ...
    xl80Data{3, 2}.Measurement - xl80Data{4, 2}.Measurement, ...
        'DisplayName', dispName, 'LineWidth', 1.5);
legend('Location', 'best');

%%
function xl80Data = load_folder_xl80_data(folderPath)
%%LOAD_FOLDER_XL80_DATA load all the XL-80 data in a selected folder
xl80Data = cell(0, 2);
% 列举当前文件夹下一层的文件/子文件夹
files = dir(folderPath);

for i = 1:length(files)
    % 获取文件或文件夹名称
    fileName = files(i).name;

    % 跳过'.'和'..'文件夹
    if strcmp(fileName, '.') || strcmp(fileName, '..')
        continue;
    end

    % 获取完整的文件或文件夹路径
    fullPath = fullfile(folderPath, fileName);
    
    % 检查是否为文件夹
    if isfolder(fullPath)
        % 如果是文件夹，递归调用函数
        xl80Data = [xl80Data;load_folder_xl80_data(fullPath)];
    else
        % 如果是文件，检查文件扩展名是否为'.csv'
        [~, ~, ext] = fileparts(fileName);
        if strcmp(ext, '.csv')
            % 如果是CSV文件，读取并处理文件
            fprintf('读取文件: %s\n', fullPath);
            xl80Data = [xl80Data;{fullPath, load_xl80_data(fullPath)}];
        end
    end
end
end

function xl80Data = load_xl80_data(filePath)
% 如果是文件，则查找表头
fid = fopen(filePath);
for ii = 1:100
    tline = fgetl(fid);
    if contains(tline, 'Time, Measurement')
        break;
    end
end
fclose(fid);

% 设置导入选项并导入数据
opts = detectImportOptions(filePath, "FileType", "delimitedtext", "NumHeaderLines", ii - 1);

xl80Data = readtable(filePath, opts);
end