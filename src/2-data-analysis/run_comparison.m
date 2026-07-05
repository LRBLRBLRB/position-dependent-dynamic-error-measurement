% Comparison between the displacements of end effector and the axial end (ids-3010 and xl-80)
close all;
clear; clc;
cd(fileparts(which("start_up.m")));

set(groot, 'DefaultAxesFontName', 'Times New Roman', 'DefaultAxesFontSize', 12);
set(groot, 'DefaultTextFontName', 'Times New Roman', 'DefaultTextFontSize', 12);
set(groot, 'DefaultAxesXMinorTick', 'on');

GEOMETRIC_ERROR_MAP = '../machine-tool-error-core/data/hmms6000/X_positioning_error.mat';

RESAMPLE_RATE = 1000;

%% --------------------------- Load Data ---------------------------
tic;

% ------------------------ Axial Displacement measured by IDS ------------------------
idsActPath = char("D:\Sync\syncthing\Data\202406-mms-dynamics\Siemens results mat\20240530 Siemens\XD_Y0_A1J80.mat");
load(idsActPath, "siemensTable");
idsActData.Time = siemensTable.time(:);
idsActData.Displacement = -1 * (siemensTable.disp1(:) - siemensTable.disp1(1));

% Positioning Error Removal of Displacement
idsActData.DispWithPosErr = idsActData.Displacement;
idsActData.Displacement = remove_positioning_error(idsActData.Time, idsActData.DispWithPosErr, GEOMETRIC_ERROR_MAP, "isDraw", false);

% Denoise
filteredIdsActData.Time = idsActData.Time;
filteredIdsActData.Displacement = denoise_displacement(idsActData.Displacement);


% ------------------------ End effector displacement measured by IDS ------------------------
idsEndPath = char("D:\Sync\syncthing\Data\202406-mms-dynamics\ids results mat\20240530 IDS\XD_Y0_A1J80.mat");
idsEndData = load(idsEndPath);
idsEndData.Time = idsEndData.Time(:);
idsEndData.Displacement = -1 * (idsEndData.Displacement(:) - idsEndData.Displacement(1));

% Positioning Error Removal of Displacement
idsEndData.DispWithPosErr = idsEndData.Displacement;
idsEndData.Displacement = remove_positioning_error(idsEndData.Time, idsEndData.DispWithPosErr, GEOMETRIC_ERROR_MAP, "isDraw", false);

% Denoise
filteredIdsEndData.Time = idsEndData.Time;
filteredIdsEndData.Displacement = denoise_displacement(idsEndData.Displacement);


% ------------------------ Axial displacement measured by XL-80 ------------------------
xl80ActPath = char("D:\Sync\syncthing\Data\202406-mms-dynamics\Siemens results mat\20240530 Siemens\XD_Y0_A1J80.mat");
load(xl80ActPath, "siemensTable");
xl80ActData.Time = siemensTable.time(:);
xl80ActData.Displacement = -1 * (siemensTable.disp1(:) - siemensTable.disp1(1));
% xl80ActData = read_xl_csv(xl80ActPath);
% xl80ActData.Time = xl80ActData.Time(:);
% xl80ActData.Displacement = xl80ActData.Displacement(:);

% Positioning Error Removal of Displacement
xl80ActData.DispWithPosErr = xl80ActData.Displacement;
xl80ActData.Displacement = remove_positioning_error(xl80ActData.Time, xl80ActData.DispWithPosErr, GEOMETRIC_ERROR_MAP, "isDraw", false);

% Denoise
filteredXl80ActData.Time = xl80ActData.Time;
filteredXl80ActData.Displacement = denoise_displacement(xl80ActData.Displacement);


% ------------------------ End effector displacement measured by XL-80 ------------------------
xl80EndPath = char('D:\Sync\syncthing\Data\202406-mms-dynamics\xl80 results\20240530 xl80\XD-Y0_A1J80.csv');
xl80EndData = read_xl_csv(xl80EndPath);
xl80EndData.Time = xl80EndData.Time(:);
xl80EndData.Displacement = -1 * (xl80EndData.Displacement(:) - xl80EndData.Displacement(1));

% Positioning Error Removal of Displacement
xl80EndData.DispWithPosErr = -1 .* xl80EndData.Displacement;
xl80EndData.Displacement = remove_positioning_error(xl80EndData.Time, xl80EndData.DispWithPosErr, GEOMETRIC_ERROR_MAP, "isDraw", false);

% Denoise
filteredXl80EndData.Time = xl80EndData.Time;
filteredXl80EndData.Displacement = denoise_displacement(xl80EndData.Displacement);

idx = filteredXl80EndData.Time <= 147.563;
filteredXl80EndData.Time = filteredXl80EndData.Time(idx);
filteredXl80EndData.Displacement = filteredXl80EndData.Displacement(idx);
t = toc

fig1 = figure('Name','Original data');
plot(filteredIdsActData.Time, filteredIdsActData.Displacement,'DisplayName','Axial - IDS');
hold on;
plot(filteredIdsEndData.Time, filteredIdsEndData.Displacement,'DisplayName','End - IDS');
plot(filteredXl80ActData.Time, filteredXl80ActData.Displacement,'DisplayName','Axial - XL80');
plot(filteredXl80EndData.Time, filteredXl80EndData.Displacement,'DisplayName','End - XL80');
legend('Location','best');
ylabel('位移 (mm)');
xlabel('时间 (s)');

%% --------------------------- Data Clipping ---------------------------
dispNode = 3900;

idx = find(filteredIdsActData.Displacement > dispNode, 1, "first");
filteredIdsActData.Time = filteredIdsActData.Time(1:idx);
filteredIdsActData.Displacement = filteredIdsActData.Displacement(1:idx);

idx = find(filteredIdsEndData.Displacement > dispNode, 1, "first");
filteredIdsEndData.Time = filteredIdsEndData.Time(1:idx);
filteredIdsEndData.Displacement = filteredIdsEndData.Displacement(1:idx);

idx = find(filteredXl80ActData.Displacement > dispNode, 1, "first");
filteredXl80ActData.Time = filteredXl80ActData.Time(1:idx);
filteredXl80ActData.Displacement = filteredXl80ActData.Displacement(1:idx);

idx = find(filteredXl80EndData.Displacement > dispNode, 1, "first");
filteredXl80EndData.Time = filteredXl80EndData.Time(1:idx);
filteredXl80EndData.Displacement = filteredXl80EndData.Displacement(1:idx);

fig1 = figure('Name','Clipped data');
plot(filteredIdsActData.Time, filteredIdsActData.Displacement,'DisplayName','Axial - IDS');
hold on;
plot(filteredIdsEndData.Time, filteredIdsEndData.Displacement,'DisplayName','End - IDS');
plot(filteredXl80ActData.Time, filteredXl80ActData.Displacement,'DisplayName','Axial - XL80');
plot(filteredXl80EndData.Time, filteredXl80EndData.Displacement,'DisplayName','End - XL80');
legend('Location','best');

%% --------------------------- Data Alignment ---------------------------
% resample
[resampledIdsActData.Time, resampledIdsActData.Displacement] = resample_signals(filteredIdsActData.Time, filteredIdsActData.Displacement, RESAMPLE_RATE);
[resampledIdsEndData.Time, resampledIdsEndData.Displacement] = resample_signals(filteredIdsEndData.Time, filteredIdsEndData.Displacement, RESAMPLE_RATE);

[resampledXl80ActData.Time, resampledXl80ActData.Displacement] = resample_signals(filteredXl80ActData.Time, filteredXl80ActData.Displacement, RESAMPLE_RATE);
[resampledXl80EndData.Time, resampledXl80EndData.Displacement] = resample_signals(filteredXl80EndData.Time, filteredXl80EndData.Displacement, RESAMPLE_RATE);

% align
[alignedIdsTime, alignedIdsActData.Displacement, alignedIdsEndData.Displacement] = align_signals( ...
    resampledIdsActData.Displacement, resampledIdsEndData.Displacement, RESAMPLE_RATE);

[alignedXl80Time, alignedXl80ActData.Displacement, alignedXl80EndData.Displacement] = align_signals( ...
    resampledXl80ActData.Displacement, resampledXl80EndData.Displacement, RESAMPLE_RATE);

% originalSigals = [filteredIdsActData;
%                   filteredIdsEndData;
%                   filteredXl80ActData;
%                   filteredXl80EndData];
% 
% alignedSignals = align_multi_signals(originalSigals);
% 
% figure;
% plot(alignedSignals.Time, alignedSignals.Displacement(:, 1),'DisplayName','Axial - IDS');
% hold on;
% plot(alignedSignals.Time, alignedSignals.Displacement(:, 2),'DisplayName','End - IDS');
% plot(alignedSignals.Time, alignedSignals.Displacement(:, 3),'DisplayName','Axial - XL80');
% plot(alignedSignals.Time, alignedSignals.Displacement(:, 4),'DisplayName','End - XL80');
% legend('Location','best');

% plot
figure('Name', '信号对齐'); 
plot(alignedIdsTime, alignedIdsActData.Displacement, '.-', 'DisplayName', 'IDS-X');
hold on;
plot(alignedIdsTime, alignedIdsEndData.Displacement, 'DisplayName', 'IDS-Endpoint');
plot(alignedXl80Time, alignedXl80ActData.Displacement, '.-', 'DisplayName', 'XL80-X');
plot(alignedXl80Time, alignedXl80EndData.Displacement, 'DisplayName', 'XL80-Endpoint');
xlabel("时间 (s)");
ylabel("位移 (mm)");
title('信号对齐');
legend('Location','best');

%% --------------------------- Comparison ---------------------------
figure('Name', '末端位移与运动轴上位移之差');
alignedIdsDiffDisplacement = alignedIdsEndData.Displacement - alignedIdsActData.Displacement;
plot(alignedIdsTime, alignedIdsDiffDisplacement, 'DisplayName', 'IDS-{\Delta}x');
hold on;

alignedXl80DiffDisplacement = alignedXl80EndData.Displacement - alignedXl80ActData.Displacement;
plot(alignedXl80Time, alignedXl80DiffDisplacement, 'DisplayName', 'XL80-{\Delta}x');

timeInv = [min(alignedIdsTime(1), alignedXl80Time(1)), max(alignedIdsTime(end), alignedXl80Time(end))];
line(timeInv, [0, 0], 'LineStyle', '--', 'Color', [0.6, 0.6, 0.6], 'HandleVisibility','off');
xlabel("时间 (s)");
ylabel("伺服环外运动误差 (mm)");
title('伺服环外运动误差的IDS和XL-80测量结果对比');
legend('Location','best');
% figure; 
% plot(alignedXl80Time, alignedIdsDiffDisplacement ./ alignedXl80DiffDisplacement);
