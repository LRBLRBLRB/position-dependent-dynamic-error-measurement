function [n,varargout] = load_folder_siemens_data(figureStruct,n,folderPath,dataNum,functionHandle,varargin)
%LOAD_FOLDER_SIEMENS_DATA 递归函数遍历文件夹及其所有子文件夹中的所有csv文件
%   此处显示详细说明

functionName = func2str(functionHandle);

% 创建输出文件夹
if strcmp(functionName,'save') && ~exist(varargin{1},'dir')
    mkdir(varargin{1});
end

% 初始化存储所有数据的结构体数组
data = struct('name',{},'siemensData',{});

% 列举当前文件夹下一层的文件/子文件夹
files = dir(folderPath);

for i = 1:length(files)
    % 获取文件或文件夹的名称
    fileName = files(i).name;

    % 跳过'.'和'..'文件夹
    if strcmp(fileName, '.') || strcmp(fileName, '..')
        continue;
    end

    % 获取完整的文件或文件夹路径
    fullPath = fullfile(folderPath,fileName);
    if strcmp(functionName,'save')
        outputName = replace(fileName,'csv','mat');
        outputFullPath = fullfile(varargin{1},outputName);
    end

    % 检查是否为文件夹
    if isfolder(fullPath)
        % 如果是文件夹，递归调用函数【如果是存文件，则需要更新调用函数句柄的参数；否则不需要】
        if strcmp(functionName,'save')
            n = load_folder_siemens_data(figureStruct,n,fullPath,dataNum,functionHandle,outputFullPath);
        else
            [n,datatmp] = load_folder_siemens_data(figureStruct,n,fullPath,dataNum,functionHandle,varargin);
            data = horzcat(data,datatmp);
        end
    else
        % 如果点击"结束"，则结束程序
        if figureStruct.waitBar.CancelRequested
            if nargout > 1
                varargout{1} = data;
            end
            return;
        end
        
        % 如果是文件，检查文件扩展名是否为'.csv'
        [~, ~, ext] = fileparts(fileName);
        if strcmp(ext, '.csv')
            % 如果是CSV文件，读取并处理文件
            n = n + 1; % 目前是第n个文件
            output = sprintf('%d.\t读取文件: %s\n',n,fullPath);
            currentString = figureStruct.hText.Value;
            currentString{end + 1} = output;
            figureStruct.hText.Value = currentString;
            scroll(figureStruct.hText,"bottom");
            fprintf('%d.\t读取文件: %s\n',n,fullPath);
            drawnow;
            siemensTable = load_siemens_data(fullPath,dataNum);

            % 处理句柄函数的操作
            switch functionName
                case 'save_data'
                    tmp.name = replace(fileName,'.csv','');
                    tmp.siemensData = siemensTable;
                    data(end + 1) = tmp;
                case 'save'
                    % 在另一个文件夹中，保存数据文件
                    save(outputFullPath,"siemensTable");
                otherwise
                    functionHandle(varargin{:});
            end

            % 更新图窗输出和命令行输出内容
            output = sprintf('%d.\t写入文件: %s\n',n,outputFullPath);
            currentString = figureStruct.hText.Value;
            currentString{end + 1} = output;
            currentString{end + 1} = '';
            figureStruct.hText.Value = currentString;
            scroll(figureStruct.hText,"bottom");
            fprintf('%d.\t写入文件: %s\n\n',n,outputFullPath);
            drawnow;
        end
    end
end

if nargout > 1
    varargout{1} = data;
end

end

