% close all;
% clear; clc;
addpath(genpath('..'));
addpath(genpath('functions'));

% filePath = "D:\Research\experiments\Siemens results\0816\Z_A3J140.csv";
% filePath = "D:\Research\experiments\Siemens results mat\20240530 Siemens\XD_Y3000_A1J5.mat";
% filePath = "D:\Research\experiments\Siemens results mat\20240531 Siemens\XA_Y0_A1J5.mat";
% dataNum = 8;
% siemensTable = load_siemens_data(filePath,dataNum);
% siemensData = table2struct(siemensData);
% load(filePath);
% siemensData.time = reshape(datanum(timestamps),[],1);
% siemensData.disp1 = reshape(siemensTable.disp1,[],1);

siemensData.time = transpose([ZA3J140.time]);
siemensData.disp1 = transpose([ZA3J140.disp1]);

% diffTime = siemensTable.time(2) - siemensTable.time(1);
% sampleRate = 1/diffTime;
% clear siemensTable;

fig1 = figure('Name','【光栅尺】位移原始图像');
plot(siemensData.time,siemensData.disp1);

%% 原始速度计算
% 计算速度，然后把每一段速度的跃冲量和到平稳所需时间给计算出来
% 计算速度
siemensData.veloTime = 0.5*(siemensData.time(1:end - 1) + siemensData.time(2:end));
siemensData.velo1 = 60*diff(siemensData.disp1)./diff(siemensData.time);

% 画速度原始图像
% screenSize = get(0,'ScreenSize'); % 获取屏幕尺寸
% figWidth = 800;  % 图窗宽度
% figHeight = 400; % 图窗高度
% figX = (screenSize(3) - figWidth) / 2; % 水平居中
% figY = screenSize(4) - figHeight - 100; % 屏幕顶端向下偏移50像素
% hFig = figure('Position',[figX,figY,figWidth,figHeight]);
% hTile = tiledlayout(hFig,2,2,'TileSpacing','compact');
% nexttile(hTile,1);
fig2 = figure('name','【光栅尺】速度原始图像');
hLine = plot(siemensData.veloTime,siemensData.velo1,'LineWidth',1);
hAxes = ancestor(hLine,'Axes');
title(hAxes,'Velocity');
% xlim([0,25]);

%% 位移分段分析
shiftTime = ceil(0.1*sampleRate);
% 使用findpeaks函数，排除噪声并寻找所有局部最值。计算局部最值离理想值的差值，作为偏差
% 下标1和2分别代表下方光栅尺和上方光栅尺
% [siemensPeaks1,siemensValleys1] = displacement_segmentation(siemensData.time,siemensData.disp1);
% siemensPeaks1.dispRange(:,1) = siemensPeaks1.ind - shiftTime;
% siemensPeaks1.dispRange(:,2) = siemensPeaks1.ind + shiftTime + 1;
% siemensValleys1.dispRange(:,1) = siemensValleys1.ind - shiftTime;
% siemensValleys1.dispRange(:,2) = siemensValleys1.ind + shiftTime + 1;
% 
% [siemensPeaks2,siemensValleys2] = displacement_segmentation(siemensData.time,siemensData.disp2);
% siemensPeaks2.dispRange(:,1) = siemensPeaks2.ind - shiftTime;
% siemensPeaks2.dispRange(:,2) = siemensPeaks2.ind + shiftTime + 1;
% siemensValleys2.dispRange(:,1) = siemensValleys2.ind - shiftTime;
% siemensValleys2.dispRange(:,2) = siemensValleys2.ind + shiftTime + 1;

siemensPeaks1 = displacement_segmentation(siemensData.time,siemensData.disp1,"PlotName","【光栅尺1】位移峰谷值");
siemensPeaks1.dispRange(:,1) = siemensPeaks1.ind - shiftTime;
siemensPeaks1.dispRange(:,2) = siemensPeaks1.ind + shiftTime + 1;
tmp = table(NaN,NaN,NaN,NaN,NaN,NaN,NaN,[NaN,NaN],'VariableNames',siemensPeaks1.Properties.VariableNames);
siemensPeaks1(end + 1,:) = tmp; % more convenient to be copied into excel

%% 速度指标计算
[velocitySegment1,desiredValue1,tLim1End] = velocity_segmentation(siemensData.velo1,sampleRate,'case','Siemens');

% 画图说明每一段的位置
fig3 = figure('Name','【光栅尺1】速度指标计算');
t1 = tiledlayout(fig3,4,3,"TileSpacing","tight",'Padding','tight');
n1 = nexttile(t1,1,[2,3]);
hLine = plot(siemensData.veloTime,siemensData.velo1,'LineWidth',0.5);
hold on;
scatter(siemensData.veloTime(velocitySegment1(:,1)),siemensData.velo1(velocitySegment1(:,1)), ...
    12,'MarkerEdgeColor',[0.8500 0.3250 0.0980],'MarkerFaceColor','flat');
scatter(siemensData.veloTime(velocitySegment1(:,2)),desiredValue1,12, ...
    'MarkerEdgeColor',[0.9290 0.6940 0.1250],'MarkerFaceColor','flat');
for ii = 1:length(desiredValue1)
    if ~isnan(desiredValue1(ii))
        plot(siemensData.veloTime(velocitySegment1(ii,1):velocitySegment1(ii,2)), ...
            siemensData.velo1(velocitySegment1(ii,1):velocitySegment1(ii,2)), ...
            'LineWidth',1.25,'LineStyle','--');
    end
end
legend('Velocity','','','Segments','Location','best');
% title(n1,'Segmented Velocity');
hAxes = ancestor(hLine,'Axes');
tLim1 = [0,siemensData.veloTime(tLim1End) + 5];
hAxes.XLim = tLim1;


% 初始化速度参数表【结构体，后转为表】
veloParam1 = struct("peakValue",{},"peakError",{}, ...
    "steadyStateValue",{},"steadyStateError",{}, ...
    "riseTime",{},"noiseLevel",{},"overshoot",{}, ...
    "oscillationFrequency",{},"settlingTime",{});

% 计算速度评价参数表
for ii = 1:size(velocitySegment1,1)
    % diffVelocitySegment = velocitySegment1(ii + 1) - velocitySegment1(ii);
    % if diffVelocitySegment > 1
    %     desiredValue = 5000; 
    % end
    % determine the desired value
    veloParam1(ii) = velo_param( ...
        siemensData.veloTime(velocitySegment1(ii,1):velocitySegment1(ii,2)), ...
        siemensData.velo1(velocitySegment1(ii,1):velocitySegment1(ii,2)),desiredValue1(ii));
end

veloParam1 = struct2table(veloParam1);

% 画图展示速度评价参数
nexttile(t1,7,[1,3]);
yyaxis left;
bar(siemensData.veloTime(velocitySegment1(:,1)),veloParam1.peakValue,1,"LineStyle","none");
yyaxis right;
plot(siemensData.veloTime(velocitySegment1(:,1)),100*veloParam1.overshoot, ...
    "Marker","diamond","Color",[0.8500 0.3250 0.0980], ...
    "MarkerEdgeColor",[0.8500 0.3250 0.0980],"MarkerFaceColor",[0.8500 0.3250 0.0980]);
ytickformat('%.1g%%');
xlim(tLim1);
legend("Peak error","Overshoot percent","Location","best");
nexttile(t1,10,[1,1]);
yyaxis left;
plot(siemensData.veloTime(velocitySegment1(:,1)),veloParam1.riseTime,'o-', ...
    'MarkerSize',3,"MarkerFaceColor",[0 0.4470 0.7410]);
hold on;
yyaxis right;
plot(siemensData.veloTime(velocitySegment1(:,1)),veloParam1.settlingTime,'square-', ...
    'MarkerSize',3,"MarkerFaceColor",[0.8500 0.3250 0.0980]);
xlim(tLim1);
legend("Rising time","Setting time","Location","best");
nexttile(t1,11,[1,1]);
plot(siemensData.veloTime(velocitySegment1(:,1)),veloParam1.noiseLevel, ...
    "Marker","o","MarkerSize",3);
xlim(tLim1);
legend("Noise level","Location","best");
nexttile(t1,12,[1,1]);
plot(siemensData.veloTime(velocitySegment1(:,1)),veloParam1.oscillationFrequency, ...
    "Marker","o","MarkerSize",3);
xlim(tLim1);
legend("Oscillation frequency","Location","best");

%% 加速度分析
% 计算加速度，然后把每一段加速度……

% 速度曲线滤波
siemensData.velo1_filtered = siemensData.velo1;
% 高斯滤波，不能解决匀加减速过程，或者匀速过程抖动对加速度计算的影响。
% siemensData.velo1_filtered = filter_gaussian(100, 1, siemensData.velo1);
% siemensData.velo2_filtered = filter_gaussian(100, 1, siemensData.velo2);

% figure;
% plot(siemensData.veloTime,siemensData.velo1);
% hold on;
% plot(siemensData.veloTime,siemensData.velo1_filtered);
% drawnow;
% figure;
% plot(siemensData.veloTime,siemensData.velo2);
% hold on;
% plot(siemensData.veloTime,siemensData.velo2_filtered);
% drawnow;

% 计算加速度
siemensData.accelTime = 0.5*(siemensData.veloTime(1:end - 1) + siemensData.veloTime(2:end));
siemensData.accel1 = diff(siemensData.velo1_filtered)./diff(siemensData.veloTime)./60000;

% 画加速度原始图像
fig5 = figure('name','【光栅尺】加速度原始图像');
hLine = plot(siemensData.accelTime,siemensData.accel1,'LineWidth',1);
hAxes = ancestor(hLine,'Axes');
hold on;
title(hAxes,'Acceleration');
grid on;
% xlim([0,25]);

%%
% 改变参数表的排列方式，以便于复制进excel表格
% paramExcel1 = save_excel(siemensPeaks1,veloParam1);
% paramExcel2 = save_excel(siemensPeaks2,veloParam2);
% 
% [pathstr, name, ~] = fileparts(filePath);
% filePath1 = fullfile(pathstr,name);
% if ~isfolder(filePath1)
%     mkdir(filePath1);
% end
% fig_save(filePath1);
% 
% % 图像平铺
% fig_tiled;
% fig_modal;

% rmpath(genpath('..'));
% rmpath(genpath('functions'));