function accelExcel = accel_param2excel(t, accel, num, accelPeaks, accelValleys, dispPeaks, options)
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

accelExcel = zeros(num, 6);

% Simulation Initialization
figure('Name', options.PlotName);
tileSimul = tiledlayout(3, 3);
nextSimul1 = nexttile(tileSimul, 1, [2, 3]);
plot(nextSimul1, t, accel);
hold(nextSimul1, "on");
drawnow;
colororder("gem12");

% 计算每段的特征峰值、峰值段RMSE和峰值时间均值（由于加速度结果比较乱，故不再给出每一段的，直接求总）
minPeakMoment = 1;
minValleyMoment = 1;
% 每段往返中，低速包括正向3、逆向2；高速包括正向4、逆向4（正向4需要归到下一个位置）
% 对于最后一个往返，高速正向只有2个。因为第三个位置已经变了
% 具体可以拿XD_Y0_A1J5的数据研究
for ii = 1:num / 2
    % 遍历每个"往返段"的正向部分（即accelPeaks部分数据），每一段包括3个低速峰和4个高速峰（但是最后一个高速峰峰值可能跟低速峰接近，最好排除）
    switch ii
        % 不同的"往返段"，加速度取得最大值时所处位置不同，所以要按不同方式归类
        case 1
            % 第一部分往返：低速包括3正2反；高速包括3正4反
            kPositiveSlow = 1:3; % 2正是因为第一个正向低速段有可能因为移动距离太小导致加速不充分。
            kPositiveFast = 4:6;
            kNegativeSlow = 1:2;
            kNegativeFast = 3:6;
        case num / 2
            % 最后一部分：低速包括3正2反；高速包括3正3反
            kPositiveSlow = 2:4;
            kPositiveFast = [1, 5:7];
            kNegativeSlow = 1:2;
            kNegativeFast = 3:5;
        otherwise
            % 其他部分往返：低速包括3正2反；高速包括4正4反
            kPositiveSlow = 2:4;
            kPositiveFast = [1, 5:7];
            kNegativeSlow = 1:2;
            kNegativeFast = 3:6;
    end
    kPositive = length(kPositiveFast) + length(kPositiveSlow); 
    kNegative = length(kNegativeFast) + length(kNegativeSlow);
    if ii == num / 2
        % 对于最后一段，最后一个peak设置为了Nan，故单独讨论；且排除最后一个峰
        maxPeakMoment = find(accelPeaks.locs < dispPeaks.locs(ii * 12 - 1) + 1, 1, "last"); 
    else
        % 找出对应"往返段"的加速度峰值的最大时刻点（加1即为下一段的最小时刻点）
        maxPeakMoment = find(accelPeaks.locs < dispPeaks.locs(ii * 12), 1, "last"); 
    end
    tmpAccelSeq = accelPeaks(minPeakMoment:maxPeakMoment, :);
    % 找出这里面加速度峰值的最大的六个，其中后三个是高速的，前三个是低速的
    [~, accelMax] = maxk(tmpAccelSeq.pks, kPositive);
    accelMax6Sorted = sort(accelMax);
    
    % （低速、正向）
    accelExcel(2 * ii - 1, 1) = mean(tmpAccelSeq.pks(accelMax6Sorted(kPositiveSlow))); % 加速度峰值
    accelExcel(2 * ii - 1, 3) = (tmpAccelSeq.locs(accelMax6Sorted(kPositiveSlow(end))) ...
        - tmpAccelSeq.locs(accelMax6Sorted(kPositiveSlow(1)))) / 2; % 加速度峰值时刻
    accelExcel(2 * ii - 1, 5) = mean(tmpAccelSeq.w(accelMax6Sorted(kPositiveSlow))); % 加速度窗宽
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs(accelMax6Sorted(kPositiveSlow)), ...
        tmpAccelSeq.pks(accelMax6Sorted(kPositiveSlow)), 36, "filled");
    drawnow; 
    pause(0.1);

    % （高速、正向）：这里用4:end而不是4:6是因为，如果最后一段排除了最后一个峰，那么最后一段就不足6个峰了
    isOut = isoutlier(tmpAccelSeq.pks(accelMax6Sorted(kPositiveFast)));
    if isOut(1) && abs(mean(tmpAccelSeq.pks(accelMax6Sorted(kPositiveFast(2:end)))) ...
            - tmpAccelSeq.pks(accelMax6Sorted(kPositiveFast(1)))) > 0.2 && length(kPositiveFast) == 4
        kPositiveFast(1) = [];
    end
    accelExcel(2 * ii, 1) = mean(tmpAccelSeq.pks(accelMax6Sorted(kPositiveFast))); % 加速度峰值
    accelExcel(2 * ii, 3) = (tmpAccelSeq.locs(accelMax6Sorted(kPositiveFast(end))) ...
        - tmpAccelSeq.locs(accelMax6Sorted(kPositiveFast(end - 2)))) / 2; % 加速度峰值时刻
    accelExcel(2 * ii, 5) = mean(tmpAccelSeq.w(accelMax6Sorted(kPositiveFast))); % 加速度窗宽
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs(accelMax6Sorted(kPositiveFast)), ...
        tmpAccelSeq.pks(accelMax6Sorted(kPositiveFast)), 36, "filled");
    drawnow; 
    pause(0.1);

    % 遍历每个"往返段"的逆向部分（即accelValleys部分数据），每一段包括2个低速峰和4个高速峰（第一个高速峰峰值可能跟低速峰峰值接近）
    if ii == num / 2
        maxValleyMoment = find(accelValleys.locs < dispPeaks.locs(ii * 12 - 1) + 1, 1, "last");
    else
        maxValleyMoment = find(accelValleys.locs < dispPeaks.locs(ii * 12) + 1, 1, "last");
    end
    tmpAccelSeq = accelValleys(minValleyMoment:maxValleyMoment, :);
    [~, accelMax] = mink(tmpAccelSeq.pks, kNegative);
    accelMax6Sorted = sort(accelMax);
    
    % （低速、逆向）
    accelExcel(2 * ii - 1, 2) = mean(tmpAccelSeq.pks(accelMax6Sorted(kNegativeSlow))); % 加速度峰值
    accelExcel(2 * ii - 1, 4) = (tmpAccelSeq.locs(accelMax6Sorted(kNegativeSlow(end))) ...
        - tmpAccelSeq.locs(accelMax6Sorted(kNegativeSlow(1)))); % 加速度峰值时刻
    accelExcel(2 * ii - 1, 6) = mean(tmpAccelSeq.w(accelMax6Sorted(kNegativeSlow))); % 加速度窗宽
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs(accelMax6Sorted(kNegativeSlow)), ...
        tmpAccelSeq.pks(accelMax6Sorted(kNegativeSlow)), 36, "filled");
    drawnow; 
    pause(0.1);

    % （高速、逆向）
    isOut = isoutlier(tmpAccelSeq.pks(accelMax6Sorted(kNegativeFast)));
    if isOut(1) && abs(mean(tmpAccelSeq.pks(accelMax6Sorted(kNegativeFast(2:end)))) ...
            - tmpAccelSeq.pks(accelMax6Sorted(kNegativeFast(1)))) > 0.2
        kNegativeFast(1) = [];
    end
    accelExcel(2 * ii, 2) = mean(tmpAccelSeq.pks(accelMax6Sorted(kNegativeFast))); % 加速度峰值
    accelExcel(2 * ii, 4) = (tmpAccelSeq.locs(accelMax6Sorted(kNegativeFast(end))) ...
        - tmpAccelSeq.locs(accelMax6Sorted(kNegativeFast(1)))) / (length(kNegativeFast) - 1); % 加速度峰值时刻
    accelExcel(2 * ii, 6) = mean(tmpAccelSeq.w(accelMax6Sorted(kNegativeFast))); % 加速度窗宽
    % Simulation
    scatter(nextSimul1, tmpAccelSeq.locs(accelMax6Sorted(kNegativeFast)), ...
        tmpAccelSeq.pks(accelMax6Sorted(kNegativeFast)), 36, "filled");
    drawnow; 
    pause(0.1);

    minPeakMoment = maxPeakMoment + 1;
    minValleyMoment = maxValleyMoment + 1;
end
% accelExcel = array2table(accelExcel, 'VariableNames', ...
%     {'forPeak', 'revPeak', 'forMoment', 'revMoment', 'forWidth', 'revWidth'});


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