% trajectory planning for x-axis dynamic performance evaluation
clear;
clc;
cd(fileparts(mfilename('fullpath')));

% inputs (SI)
jerk = 100;
acceTol = 1.5;
veloMax = 10000/60000; % mm/min -> m/s
posMin = 0.5;
posMax = 5.5;
posInv = 1;
tInt = 0.001;

%% motion planning
% S-shaped acceleration from static pose followed by moving with a constant
% velocity

% 1.1、V0=0;V3=veloMax;S0=(posMin+posMax)/2
posInit = (posMin + posMax)/2; % initial position

[acceMax, sParam] = s_traj_para(jerk, acceTol, 0, veloMax, 'first', posInit);
tTmp = 0:tInt:sParam(4, 1); % 时间对齐，即结束时间必须能被tint整除，避免末尾时间间隔不同
tList = tTmp;
posList = s_traj_pos(0, jerk, acceMax, sParam, tTmp);
veloList = s_traj_velo(0, jerk, acceMax, sParam, tTmp);
acceList = s_traj_acce(0, jerk, acceMax, sParam, tTmp);
jerkList = s_traj_jerk(0, jerk, sParam, tTmp);

% % 1.2、constant-speed stage of the first segment
% % seems that this part can be put in the while-loop
% posEnd = 1;
% tEnd = (posEnd - posList(end))/veloList(end);
% tTmp = tList(end):tInt:tEnd;
% nTmp = length(tTmp);
% posList = [posList, posList(end) + veloList(end)*(tTmp - tList(end))];
% veloList = [veloList, veloList(end)*ones(1, nTmp)];
% acceList = [acceList, zeros(1, nTmp)];
% jerkList = [jerkList, zeros(1, nTmp)];
% tList = [tList, tTmp];

%% motion planning of the middlist loops
% calculate the displacement of a s-shaped acce/dcce reversing process
sLen = s_traj_len(jerk, acceTol, veloMax);
sLen = ceil(sLen*1E5)/1E5;

posInitSeg = ceil((posInit - posMin)/posInv);
posEnd = posMin + posInitSeg*posInv;

ind = -1;
while posList(end) > posMin
    % a reciprocating cycle starts with 
    % 2.1、constant-speed stage in positive direction
    clear tTmp;
    ind = ind + 1;
    posEnd = posEnd + ind*posInv - sLen;
    tEnd = (posEnd - posList(end))/veloList(end);
    tTmp = tList(end):tInt:(tList(end) + tEnd);
    nTmp = length(tTmp);
    posList = [posList, posList(end) + veloList(end)*(tTmp - tList(end))];
    veloList = [veloList, veloList(end)*ones(1, nTmp)];
    acceList = [acceList, zeros(1, nTmp)];
    jerkList = [jerkList, zeros(1, nTmp)];
    tList = [tList, tTmp];

    % 2.2、S-shaped velocity changing stage from positive to negative
    % direction (S0=S3；V0=-V3=veloMax)
    clear acceMax sParam tTmp;
    [acceMax, sParam] = s_traj_para(-1*jerk, -1*acceTol, veloMax, -1*veloMax, 'middle', posEnd);
    tTmp = 0:tInt:sParam(4, 1); 
    tList = [tList, tList(end) + tTmp];
    posList = [posList, s_traj_pos(0, -1*jerk, acceMax, sParam, tTmp)];
    veloList = [veloList, s_traj_velo(0, -1*jerk, acceMax, sParam, tTmp)];
    acceList = [acceList, s_traj_acce(0, -1*jerk, acceMax, sParam, tTmp)];
    jerkList = [jerkList, s_traj_jerk(0, -1*jerk, sParam, tTmp)];

    % 2.3、constant-speed stage in negative direction
    clear tTmp;
    ind = ind + 1;
    posEnd = posEnd - ind*posInv;
    if posEnd > posMax
        posEnd = posMax + sLen;
    else
        posEnd = posEnd + sLen;
    end
    tEnd = (posEnd - posList(end))/veloList(end);
    tTmp = tList(end):tInt:(tList(end) + tEnd);
    nTmp = length(tTmp);
    posList = [posList, posList(end) + veloList(end)*(tTmp - tList(end))];
    veloList = [veloList, veloList(end)*ones(1, nTmp)];
    acceList = [acceList, zeros(1, nTmp)];
    jerkList = [jerkList, zeros(1, nTmp)];
    tList = [tList, tTmp];

    % 2.4、S-shaped velocity changing stage from negative to positive
    % direction (2、S0=S3；V0=-V3=-1*veloMax)
    clear acceMax sParam tTmp;
    [acceMax, sParam] = s_traj_para(jerk, acceTol, -1*veloMax, veloMax, 'middle', posEnd);
    tTmp = 0:tInt:sParam(4, 1); 
    tList = [tList, tList(end) + tTmp];
    posList = [posList, s_traj_pos(0, jerk, acceMax, sParam, tTmp)];
    veloList = [veloList, s_traj_velo(0, jerk, acceMax, sParam, tTmp)];
    acceList = [acceList, s_traj_acce(0, jerk, acceMax, sParam, tTmp)];
    jerkList = [jerkList, s_traj_jerk(0, jerk, sParam, tTmp)];
    % break;
end

%% motion planning of the last reverse segment
% 3.1、constant-speed stage of the last segment
clear acceMax sParam tTmp;
[acceMax, sParam] = s_traj_para(-1*jerk, -1*acceTol, veloMax, 0, 'final', posMax);
posEnd = min(sParam(:, 3));
tEnd = (posEnd - posList(end))/veloList(end);
tTmp = tList(end):tInt:(tList(end) + tEnd);
nTmp = length(tTmp);
posList = [posList, posList(end) + veloList(end)*(tTmp - tList(end))];
veloList = [veloList, veloList(end)*ones(1, nTmp)];
acceList = [acceList, zeros(1, nTmp)];
jerkList = [jerkList, zeros(1, nTmp)];
tList = [tList, tTmp];

% 3.2、V0=veloMax;V3=0;S3=posMax
clear tTmp;
tTmp = 0:tInt:sParam(4, 1); 
tList = [tList, tList(end) + tTmp];
posList = [posList, s_traj_pos(0, -1*jerk, acceMax, sParam, tTmp)];
veloList = [veloList, s_traj_velo(0, -1*jerk, acceMax, sParam, tTmp)];
acceList = [acceList, s_traj_acce(0, -1*jerk, acceMax, sParam, tTmp)];
jerkList = [jerkList, s_traj_jerk(0, -1*jerk, sParam, tTmp)];

%% presentation of the whole trajectory
figure;
tl1 = tiledlayout(4, 1);
ax11 = nexttile;
plot(ax11, tList, posList, 'LineWidth', 1.5);
posTick = posMin:posInv:posMax;
% posTick = [posTick(1:posInitSeg), posInit, posTick(posInitSeg + 1:end)];
posTickLabel = cell(1, length(posTick));
posTickLabel{1} = posTick(1);
% posTickLabel{posInitSeg + 1} = posTick(posInitSeg + 1);
posTickLabel{end} = posTick(end);
set(ax11, "YTick", posTick, "YTickLabel", posTickLabel, "XTickLabel", '');
grid on;
ax12 = nexttile;
plot(ax12, tList, veloList, 'LineWidth', 1.5);
set(ax12, "XTickLabel", '');
grid on;
ax13 = nexttile;
plot(ax13, tList, acceList, 'LineWidth', 1.5);
set(ax13, "XTickLabel", '');
grid on;
ax14 = nexttile;
plot(ax14, tList, jerkList, 'LineWidth', 1.5);
grid on;


% if used to draw in Visio or PPT, then the tick labels and axis labels
% should be removed
xlab11 = get(ax11, 'xticklabel');
ylab11 = get(ax11, 'yticklabel');
xlab12 = get(ax12, 'xticklabel');
ylab12 = get(ax12, 'yticklabel');
xlab13 = get(ax13, 'xticklabel');
ylab13 = get(ax13, 'yticklabel');
xlab14 = get(ax14, 'xticklabel');
ylab14 = get(ax14, 'yticklabel');
while true
    [uiIndex, uiTf] = listdlg('ListString', ...
        {'Plot for showing', 'Plot for saving'}, ...
        'InitialValue', 1, ...
        'PromptString', 'Select the plotting behaviour:', ...
        'SelectionMode', 'single', 'ListSize', [100, 50]);
    if ~uiTf
        break;
    end
    if uiIndex == 1
        % show the results
        set(ax11, 'xticklabel', xlab11, 'yticklabel', ylab11);
        ylabel(ax11, 's (m)', 'Rotation', 0);
        set(ax12, 'xticklabel', xlab12, 'yticklabel', ylab12);
        ylabel(ax12, 'v (m/s)', 'Rotation', 0);
        set(ax13, 'xticklabel', xlab13, 'yticklabel', ylab13);
        ylabel(ax13, 'a (m/s^2)', 'Rotation', 0);
        set(ax14, 'xticklabel', xlab14, 'yticklabel', ylab14);
        ylabel(ax14, 'j (m/s^3)', 'Rotation', 0);
        xlabel(tl1, 'time(s)');
    else
        set(ax11, 'xticklabel', [], 'yticklabel', [], 'ylabel', []);
        set(ax12, 'xticklabel', [], 'yticklabel', [], 'ylabel', []);
        set(ax13, 'xticklabel', [], 'yticklabel', [], 'ylabel', []);
        set(ax14, 'xticklabel', [], 'yticklabel', [], 'ylabel', []);
        xlabel(tl1, []);
    end
end

% save the dataset
% -------------------- select which data to save --------------------
[dataFile, dataDir] = uiputfile({'*.csv', 'Comma-seperated-values file(*.csv)'; ...
    '*.*', 'All files'}, 'Enter the file to save the trajactory data');
if ~dataFile
    return;
end
dataPath = fullfile(dataDir, dataFile);
[~, ~, fileExts] = fileparts(dataFile);
switch fileExts
    case ".csv"
        writematrix([tList', posList'], dataPath);
    otherwise
        fprintf("No file saved.");
end