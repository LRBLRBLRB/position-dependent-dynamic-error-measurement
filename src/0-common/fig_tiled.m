function fig_tiled(titlebarHeight,taskbarHeight)
%FIG_TILED 平铺排列所有MATLAB图窗
%   

arguments
    titlebarHeight double = 50 % 估算标题栏的高度，通常标题栏高度为 30 像素
    taskbarHeight double = 80
end

% 获取屏幕的尺寸
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);

% 查找所有图窗
figs = findobj('Type', 'figure');

% 可用的屏幕区域（去除任务栏和标题栏）
usableHeight = screenHeight - titlebarHeight;

% 计算每个图窗的尺寸
numFigures = numel(figs);
rows = ceil(sqrt(numFigures)); % 确定行数
cols = ceil(numFigures / rows); % 确定列数
figureWidth = floor(screenWidth / cols);
figureHeight = floor(usableHeight / rows);

% 平铺图窗
for i = 1:numFigures
    fig = figs(i);
    no = fig.Number;
    % 计算图窗的位置
    row = floor((no - 1) / cols) + 1;
    col = mod((no - 1), cols) + 1;
    left = (col - 1) * figureWidth;
    bottom = screenHeight - row * figureHeight; % 需要减去任务栏的高度

    % 设置图窗的位置和大小
    set(fig, 'Position', [left, bottom, figureWidth, figureHeight - taskbarHeight]);
    % set(fig,'xticklabel',get(gca,'xtick'),'yticklabel',get(gca,'ytick'));
end

end