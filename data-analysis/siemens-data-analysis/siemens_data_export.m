% 连续地把同一个文件夹中的所有csv文件，都参与到导出工作中，并分别存储到一个专门的文件夹
clear; clc;
addpath(genpath('functions'));

folderPath = "D:\Research\experiments\Siemens results\0816";
outputPath = "D:\Research\experiments\Siemens results mat\0816";
dataNum = 8;

% 创建图窗来显示导入进度
hFig = uifigure('Name','Output Window','NumberTitle','on');
hPos = get(hFig,'Position');
hPos(3) = hPos(3)*1.2;
set(hFig,'Position',hPos);
hLayout = uigridlayout(hFig,[2,1],'RowHeight',{'fit','1x'},'ColumnWidth',{'1x'});
hLabel = uilabel(hLayout,"Text","Loaded Files");
hLabel.Layout.Row = 1;
hLabel.Layout.Column = 1;

figStruct.hText = uitextarea(hLayout,'WordWrap','on','Editable','off', ...
    'BackgroundColor',[0.96 0.96 0.96],"FontWeight","bold");
figStruct.hText.Layout.Row = 2;
figStruct.hText.Layout.Column = 1;
figStruct.hText.Value = {'Start. '};

figStruct.waitBar = uiprogressdlg(hFig,'Message','导入中……','Title','结束导入',...
        'Indeterminate','on','Cancelable','on','CancelText','结束');
drawnow;

load_folder_siemens_data(figStruct,0,folderPath,dataNum,@save,outputPath);

close(figStruct.waitBar);

rmpath(genpath('functions'));