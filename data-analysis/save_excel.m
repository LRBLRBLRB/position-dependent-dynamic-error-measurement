function paramExcel = save_excel(dispParam, veloParam)
%SAVE_EXCEL 此处显示有关此函数的摘要
%   此处显示详细说明

    function cal_mean(paramCol)
        paramExcel(paramRow, paramCol) = mean(paramExcel(paramRow, (paramCol - 6):2:(paramCol - 2)), "omitmissing");
        % paramExcel(paramRow, paramCol) = paramExcel(paramRow, paramCol) - floor(paramExcel(paramRow, paramCol));
        paramExcel(paramRow, paramCol + 1) = mean(paramExcel(paramRow, (paramCol - 5):2:(paramCol - 1)), "omitmissing");
        % paramExcel(paramRow, paramCol + 1) = paramExcel(paramRow, paramCol + 1) - floor(paramExcel(paramRow, paramCol + 1));
    end

    function cal_time_mean(paramCol)
        % 位移、速度和加速度的时间计算时，都需要排除每一小段的最后一个数据，即上一段结束前往下一段对应的数据
        % 这里使用剔除离群点实现
        tmp = paramExcel(paramRow, (paramCol - 6):2:(paramCol - 2));
        tmp = rmoutliers(tmp);
        paramExcel(paramRow, paramCol) = mean(tmp, "omitmissing");
        tmp = paramExcel(paramRow, (paramCol - 5):2:(paramCol - 1));
        tmp = rmoutliers(tmp);
        paramExcel(paramRow, paramCol + 1) = mean(tmp, "omitmissing");
    end

    function cal_character
        paramExcel(paramRow, 1:6) = dispParam.pks(dispRow:(dispRow + 5)); % peak value of displacement
        cal_mean(7);
        paramExcel(paramRow, 9:14) = dispParam.error(dispRow:(dispRow + 5)); % peak error of displacement
        cal_mean(15);
        paramExcel(paramRow, 17:22) = dispParam.locs(dispRow:(dispRow + 5)); % peak location of displacement
        cal_mean(23);
        paramExcel(paramRow, 25:30) = dispParam.w(dispRow:(dispRow + 5)); % peak width of displacement
        cal_mean(31);

        paramExcel(paramRow, 33:38) = veloParam.peakValue(veloRow:(veloRow + 5)); % peak value of velocity
        cal_mean(39);
        paramExcel(paramRow, 41:46) = veloParam.peakMoment(veloRow:(veloRow + 5)); % peak moment of velocity
        cal_time_mean(47);
        paramExcel(paramRow, 49:54) = veloParam.steadyStateValue(veloRow:(veloRow + 5)); % steady state value of velocity
        cal_mean(55);
        paramExcel(paramRow, 57:62) = veloParam.steadyStateMoment(veloRow:(veloRow + 5)); % steady state moment of velocity
        cal_time_mean(63);
        paramExcel(paramRow, 65:70) = veloParam.startValue(veloRow:(veloRow + 5)); % start value of velocity
        cal_mean(71);
        paramExcel(paramRow, 73:78) = veloParam.startMoment(veloRow:(veloRow + 5)); % start moment of velocity
        % cal_mean(79);
        paramExcel(paramRow, 81:86) = veloParam.riseTime(veloRow:(veloRow + 5)); % rising time of velocity
        cal_time_mean(87);
        % paramExcel(paramRow, 73:78) = veloParam.noiseLevel(veloRow:(veloRow + 5)); % noise level of velocity
        % cal_mean(79);
        % paramExcel(paramRow, 81:86) = veloParam.overshoot(veloRow:(veloRow + 5)); % overshoot of velocity
        % cal_mean(87);
        % paramExcel(paramRow, 89:94) = veloParam.oscillationFrequency(veloRow:(veloRow + 5)); % oscillation frequency of velocity
        % cal_mean(95);
        % paramExcel(paramRow, 73:78) = veloParam.settlingTime(veloRow:(veloRow + 5)); % settling time of velocity
        % cal_time_mean(79);
    end

paramRow = 1; % row number in paramExcel
dispRow = 1; % row number in dispParam
veloRow = 1; % row number in veloParam

num = length(dispParam.pks);
if ~isinteger(num / 6)
    % the displacememt measurement of the last location has been stopped before
    % the axis stopped running
    % here, add NaN for the missing data
    tmp = table(NaN, NaN, NaN, NaN, NaN, NaN, NaN, [NaN, NaN], 'VariableNames', dispParam.Properties.VariableNames);
    for ii = num + 1:ceil(num / 6) * 6
        dispParam(ii, :) = tmp;
    end
end


paramExcel = nan(ceil(num / 6), 80);

for ii = 1:ceil(size(paramExcel, 1) / 2)
    cal_character; % feeadrate = 5000
    paramRow = paramRow + 1;
    dispRow = dispRow + 6;
    veloRow = veloRow + 6;
    if paramRow > size(paramExcel, 1)
        break;
    end
    cal_character; % feedrate = 30000
    paramRow = paramRow + 1;
    dispRow = dispRow + 6;
    veloRow = veloRow + 7;
end
end