function accelExcel = accel_param2excel_C(t, accel, num, accelPeaks, accelValleys, dispPeaks, options)
%ACCEL_PARAM2EXCEL  加速度指标另外计算

arguments
    t
    accel
    num
    accelPeaks
    accelValleys
    dispPeaks
    options.PlotName string = "加速度数据最终提取结果（仿真）"
end

PAUSE_SECONDS = 0.1;

accelExcel = zeros(num, 6);

% Simulation Initialization
figure('Name', options.PlotName);
tileSimul = tiledlayout(3, 3);
nextSimul1 = nexttile(tileSimul, 1, [2, 3]);
plot(nextSimul1, t, accel);
hold(nextSimul1, "on");
drawnow;
colororder("gem12");

    function accelExcel = accel_param
        accelExcel = zeros(1, 3);
        accelExcel(1) = mean(tmpAccelSeq.pks); % 加速度峰值
        accelExcel(2) = (tmpAccelSeq.locs(end) - tmpAccelSeq.locs(1)) / (size(tmpAccelSeq, 1) - 1); % 加速度峰值时刻
        accelExcel(3) = mean(tmpAccelSeq.w); % 加速度窗宽
    end

% 计算每段的特征峰值、峰值段RMSE和峰值时间均值（由于加速度结果比较乱，故不再给出每一段的，直接求总）
sepMin = 0;
for ii = 1:num / 2
    % 对于每个"往返段"
    sepLowHigh = mean(dispPeaks.locs((ii - 1) * 12 + (5:6))); % 每段低速与高速段的分界点
    sepMax = dispPeaks.locs(ii * 12) + 0.5;
    if isnan(sepMax), sepMax = inf; end

    % （低速、正向）
    tmpAccelSeq = accelPeaks(all([accelPeaks.locs > sepMin, accelPeaks.locs < sepLowHigh], 2), :);
    % isOut = all([isoutlier(tmpAccelSeq.pks), abs(tmpAccelSeq.pks - mean(tmpAccelSeq.pks)) > 0.01], 2);
    % tmpAccelSeq(isOut, :) = [];
    accelExcel(2 * ii - 1, 1:2:5) = accel_param; % 加速度参数计算
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs, tmpAccelSeq.pks, 36, "filled");
    drawnow;
    pause(PAUSE_SECONDS);
    
    % （低速、逆向）
    tmpAccelSeq = accelValleys(all([accelValleys.locs > tmpAccelSeq.locs(1), accelValleys.locs < tmpAccelSeq.locs(end)], 2), :);
    accelExcel(2 * ii - 1, 2:2:6) = accel_param; % 加速度参数计算
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs, tmpAccelSeq.pks, 36, "filled");
    drawnow; 
    pause(PAUSE_SECONDS);

    % （高速、正向）
    tmpAccelSeq = accelPeaks(all([accelPeaks.locs > sepLowHigh, accelPeaks.locs < sepMax], 2), :);
    % isOut = all([isoutlier(tmpAccelSeq.pks), abs(tmpAccelSeq.pks - mean(tmpAccelSeq.pks)) > 0.01], 2);
    % tmpAccelSeq(isOut, :) = [];
    accelExcel(2 * ii, 1:2:5) = accel_param; % 加速度参数计算
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs, tmpAccelSeq.pks, 36, "filled");
    drawnow; 
    pause(PAUSE_SECONDS);

    % （高速、逆向）：去掉最外侧的两个
    tmpAccelSeq = accelValleys(all([accelValleys.locs > tmpAccelSeq.locs(1), accelValleys.locs < tmpAccelSeq.locs(end)], 2), :);
    accelExcel(2 * ii, 2:2:6) = accel_param; % 加速度参数计算
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs, tmpAccelSeq.pks, 36, "filled");
    drawnow; 
    pause(PAUSE_SECONDS);

    sepMin = sepMax;
end
% accelExcel = array2table(accelExcel, 'VariableNames', ...
%     {'forPeak', 'revPeak', 'forMoment', 'revMoment', 'forWidth', 'revWidth'});

pause(10*PAUSE_SECONDS);
nexttile(tileSimul, 7);
bar(accelExcel(:, 1:2), "EdgeColor", "flat", "FaceAlpha", 0.5);
hold("on");
title('Peak Error');
% legend('forPeak', 'revPeak', 'Location', 'southoutside');
nexttile(tileSimul, 8);
bar(accelExcel(:, 3:4), "EdgeColor", "flat", "FaceAlpha", 0.5);
hold("on");
title('Peak Moment');
% legend('forMoment', 'revMoment', 'Location', 'southoutside');
nexttile(tileSimul, 9);
bar(accelExcel(:, 5:6), "EdgeColor", "flat", "FaceAlpha", 0.5);
hold("on");
title('Peak Width');
% legend('forWidth', 'revWidth', 'Location', 'southoutside');

% pause;
% close(figSimul);
% clear("figSimul");
end