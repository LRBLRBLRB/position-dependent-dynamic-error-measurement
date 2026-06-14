function fig_modal
%FIG_MODAL 此处显示有关此函数的摘要
%   此处显示详细说明

% 获取所有图窗的句柄
figHandles = findall(0, 'Type', 'figure');

% 遍历所有图窗
for i = 1:length(figHandles)
    set(figHandles(i), 'WindowStyle', 'modal');
    set(figHandles(i), 'WindowStyle', 'normal');
end
drawnow;

end