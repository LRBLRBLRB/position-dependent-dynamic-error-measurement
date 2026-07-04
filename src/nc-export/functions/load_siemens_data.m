function [siemensTable, matrixHead] = load_siemens_data(filePath, dataNum)
%LOAD_SIEMENS_DATA 此处显示有关此函数的摘要
%   此处显示详细说明

% 设置导入选项并导入数据
opts = delimitedTextImportOptions("NumVariables", dataNum + 1);

% 指定范围和分隔符
opts.Delimiter = ", ";

% 指定列名称和类型
% 新：时间 插补结果X1 插补结果X13 光栅尺X1 光栅尺X13 电流X1 电流X13 扭矩X1 扭矩X13
opts.DataLines = [1, dataNum + 4];
matrixHead = readmatrix(filePath, opts);

% 根据表头信息确定是X轴/Y轴的数据
if any(contains(matrixHead(:, 5), '/Nck/!SD/nckServoDataActPos2ndEnc64 [u1  1]'))
    axis = [1 14]; % X
elseif any(contains(matrixHead(:, 5), '/Nck/!SD/nckServoDataActPos2ndEnc64 [u1  2]'))
    axis = [2 19]; % Y
else
    error('We cannot tell if the tested axis is X or Y.')
end
tmpNameInd = ones(1, 9);
[tmpNameInd(2), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SEMA/cmdContrPos [u1  %d]', axis(1))));
[tmpNameInd(3), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SEMA/cmdContrPos [u1  %d]', axis(2))));
[tmpNameInd(4), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SD/nckServoDataActPos2ndEnc64 [u1  %d]', axis(1))));
[tmpNameInd(5), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SD/nckServoDataActPos2ndEnc64 [u1  %d]', axis(2))));
[tmpNameInd(6), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SD/nckServoDataActCurr64 [u1  %d]', axis(1))));
[tmpNameInd(7), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SD/nckServoDataActCurr64 [u1  %d]', axis(2))));
[tmpNameInd(8), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SD/nckServoDataCmdTorque64 [u1  %d]', axis(1))));
[tmpNameInd(9), ~] = find(strcmp(matrixHead, sprintf('/Nck/!SD/nckServoDataCmdTorque64 [u1  %d]', axis(2))));

tmpName = ["time", "int1", "int2", "disp1", "disp2", "current1", "current2", "torque1", "torque2"];

opts.DataLines = [dataNum + 4, Inf];
opts.VariableNames = tmpName(tmpNameInd);
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double"];

% 指定文件级属性
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.VariableNamingRule = 'preserve';

% 导入数据
siemensTable = readtable(filePath, opts);

end

