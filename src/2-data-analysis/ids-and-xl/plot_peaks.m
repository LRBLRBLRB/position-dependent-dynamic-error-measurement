function plot_peaks(t,x,dataPeaks,dataValleys,options)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明

arguments
    t
    x
    dataPeaks
    dataValleys
    options.WindowStyle {mustBeMember(options.WindowStyle, ...
        {'normal','modal','docked'})} = 'normal'
    options.WindowState {mustBeMember(options.WindowState, ...
        {'normal','minimized','maximized','fullscreen'})} = 'normal'
    options.PlotName = "峰值位置"
    options.Text logical = false
end

% 绘制原始数据和检测到的峰谷值及其范围
hFig = figure('Name',options.PlotName);
set(hFig,'WindowStyle',options.WindowStyle, ...
    'WindowState',options.WindowState);
hTile = tiledlayout(3,1);
nexttile(hTile,1,[2,1]);
hLine = plot(t,x,'Tag','Signal');
hAxes = ancestor(hLine,'Axes');
hAxes.XLim = [0,t(end)];
% grid(hAxes,'on');

ylabel('Displacement (mm)');

% 峰值
color = get(hLine,'Color');
hLine = line(dataPeaks.locs,dataPeaks.pks,'Parent',hAxes, ...
    'Marker','v','MarkerFaceColor',color,'Color',color, ...
    'LineStyle','none','tag','Peak');
signal.internal.findpeaks.plotpkmarkers(hLine,dataPeaks.pks);

% 谷值
color = [0.8500 0.3250 0.0980];
hLine = line(dataValleys.locs,dataValleys.pks,'Parent',hAxes, ...
    'Marker','^','MarkerFaceColor',color,'Color',color, ...
    'LineStyle','none','tag','Peak');
signal.internal.findpeaks.plotpkmarkers(hLine,dataValleys.pks);

nexttile(hTile,3);
hBar1 = bar(dataPeaks.locs,dataPeaks.error,0.35, ...
    'EdgeColor','none','FaceColor',[0 0.4470 0.7410]);
hold on;
hBar2 = bar(dataValleys.locs,dataValleys.error,0.35, ...
    'EdgeColor','none','FaceColor',[0.8500 0.3250 0.0980]);
hAxes = ancestor(hBar2,'Axes');
hAxes.XLim = [0,t(end)];

xlabel('Time (s)');
ylabel('\DeltaDisp (mm)');

if options.Text
    text(hBar1(1).XEndPoints,hBar1(1).YEndPoints,string(dataPeaks.error), ...
        'HorizontalAlignment','center','VerticalAlignment','top');
    text(hBar2(1).XEndPoints,hBar2(1).YEndPoints,string(dataValleys.error), ...
        'HorizontalAlignment','center','VerticalAlignment','top');
end
end