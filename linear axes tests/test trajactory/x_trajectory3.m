% trajectory planning for x-axis dynamic performance evaluation
clear;
clc;

% inputs (SI)
jerk = 140;
acceTol = 3;
veloParam = [5000,30000]./60000; % mm/min -> m/s
posParam = [0,-1.4,-3.1,0];
% posMin = 0;
% posMax = -3.2;
% posNo = 3; % No. of reciprocating areas
posRev = -0.1; % position reversal distance
tInt = 0.001;
repeatance = 3;

%% 0
t5 = 0:tInt:3;
tList = t5;
posList = zeros(1,length(t5));
veloList = zeros(1,length(t5));
accelList = zeros(1,length(t5));
jerkList = zeros(1,length(t5));

%% 1

for ii = 1:length(posParam) - 1
    for jj = 1:length(veloParam)
        % S-shaped speed-rising stage, from 0 to -max
        clear acceMax sParam jerkTmp;
        jerkTmp = -1*jerk;
        [acceMax,sParam] = s_traj_para(jerkTmp,-1*acceTol,0,-1*veloParam(jj),'first',posParam(ii));
        t1 = 0:tInt:sParam(4,1); % 时间对齐，即结束时间必须能被tint整除，避免末尾时间间隔不同
        pos1 = s_traj_pos(t1(1),jerkTmp,acceMax,sParam,t1);
        dist1 = abs(pos1(end) - pos1(1));
        velo1 = s_traj_velo(t1(1),jerkTmp,acceMax,sParam,t1);
        accel1 = s_traj_acce(t1(1),jerkTmp,acceMax,sParam,t1);
        jerk1 = s_traj_jerk(t1(1),jerkTmp,sParam,t1);
        tList0 = t1;
        posList0 = pos1;
        veloList0 = velo1;
        accelList0 = accel1;
        jerkList0 = jerk1;

        % 3 S-shaped speed-changing stage, from negative to positive
        clear acceMax sParam jerkTmp;
        jerkTmp = jerk;
        [acceMax,sParam] = s_traj_para(jerkTmp,acceTol,-1*veloParam(jj),veloParam(jj),'middle',posParam(ii) + posRev);
        t3 = 0:tInt:sParam(4,1);
        pos3 = s_traj_pos(t3(1),jerkTmp,acceMax,sParam,t3);
        dist3 = max(pos3) - min(pos3);
        velo3 = s_traj_velo(t3(1),jerkTmp,acceMax,sParam,t3);
        accel3 = s_traj_acce(t3(1),jerkTmp,acceMax,sParam,t3);
        jerk3 = s_traj_jerk(t3(1),jerkTmp,sParam,t3);
    
        % 5 S-shaped velocity changing stage from positive to 0
        clear acceMax sParam jerkTmp;
        jerkTmp = -1*jerk;
        [acceMax,sParam] = s_traj_para(jerkTmp,-1*acceTol,veloParam(jj),0,'final',posParam(ii));
        t5 = 0:tInt:sParam(4,1); 
        pos5 = s_traj_pos(t5(1),jerkTmp,acceMax,sParam,t5);
        dist5 = abs(pos5(end) - pos5(1));
        velo5 = s_traj_velo(t5(1),jerkTmp,acceMax,sParam,t5);
        accel5 = s_traj_acce(t5(1),jerkTmp,acceMax,sParam,t5);
        jerk5 = s_traj_jerk(t5(1),jerkTmp,sParam,t5);
    
        % 2 constant-speed stage in negative direction
        tConstant = (abs(posRev) - dist1 - dist3)/abs(velo1(end));
        t2 = 0:tInt:tConstant;
        nTmp = length(t2);
        posList0 = [posList0,posList0(end) + velo1(end)*t2];
        veloList0 = [veloList0,velo1(end)*ones(1,nTmp)];
        accelList0 = [accelList0,zeros(1,nTmp)];
        jerkList0 = [jerkList0,zeros(1,nTmp)];
        tList0 = [tList0,t2 + tList0(end)];
    
        tList0 = [tList0,tList0(end) + t3];
        posList0 = [posList0,pos3];
        veloList0 = [veloList0,velo3];
        accelList0 = [accelList0,accel3];
        jerkList0 = [jerkList0,jerk3];
    
        % 4 constant-speed stage in positive direction
        tConstant = (abs(posRev) - dist3 - dist5)/abs(velo3(end));
        t4 = 0:tInt:tConstant;
        nTmp = length(t4);
        posList0 = [posList0,posList0(end) + velo3(end)*t4];
        veloList0 = [veloList0,velo3(end)*ones(1,nTmp)];
        accelList0 = [accelList0,zeros(1,nTmp)];
        jerkList0 = [jerkList0,zeros(1,nTmp)];
        tList0 = [tList0,t4 + tList0(end)];
    
        tList0 = [tList0,tList0(end) + t5];
        posList0 = [posList0,pos5];
        veloList0 = [veloList0,velo5];
        accelList0 = [accelList0,accel5];
        jerkList0 = [jerkList0,jerk5];
    
        % repeat for 3 times
        tList = [tList,tList0 + tList(end)];
        tList = [tList,tList0 + tList(end)];
        tList = [tList,tList0 + tList(end)];
        posList = [posList,posList0,posList0,posList0];
        veloList = [veloList,veloList0,veloList0,veloList0];
        accelList = [accelList,accelList0,accelList0,accelList0];
        jerkList = [jerkList,jerkList0,jerkList0,jerkList0];
    end

    % travel to the next reciprocatin area
    distTravel = (posParam(ii + 1) - posList(end));
    veloTravel = sign(distTravel)*max(veloParam);

    % speed rising at travel segments
    clear acceMax sParam jerkTmp;
    jerkTmp = sign(distTravel)*jerk;
    [acceMax,sParam] = s_traj_para(jerkTmp,sign(distTravel)*acceTol,0,veloTravel,'first',posParam(ii));
    t1 = 0:tInt:sParam(4,1); % 时间对齐，即结束时间必须能被tint整除，避免末尾时间间隔不同
    pos1 = s_traj_pos(t1(1),jerkTmp,acceMax,sParam,t1);
    dist1 = abs(pos1(end) - pos1(1));
    velo1 = s_traj_velo(t1(1),jerkTmp,acceMax,sParam,t1);
    accel1 = s_traj_acce(t1(1),jerkTmp,acceMax,sParam,t1);
    jerk1 = s_traj_jerk(t1(1),jerkTmp,sParam,t1);
    tList = [tList,t1 + tList(end)];
    posList = [posList,pos1];
    veloList = [veloList,velo1];
    accelList = [accelList,accel1];
    jerkList = [jerkList,jerk1];

    % speed falling
    clear acceMax sParam jerkTmp;
    jerkTmp = -1*sign(distTravel)*jerk;
    [acceMax,sParam] = s_traj_para(jerkTmp,-1*sign(distTravel)*acceTol,veloTravel,0,'final',posParam(ii + 1));
    t5 = 0:tInt:sParam(4,1); 
    pos5 = s_traj_pos(t5(1),jerkTmp,acceMax,sParam,t5);
    dist5 = abs(pos5(end) - pos5(1));
    velo5 = s_traj_velo(t5(1),jerkTmp,acceMax,sParam,t5);
    accel5 = s_traj_acce(t5(1),jerkTmp,acceMax,sParam,t5);
    jerk5 = s_traj_jerk(t5(1),jerkTmp,sParam,t5);

    % constant speed
    tConstant = (abs(distTravel) - dist1 - dist5)/abs(veloTravel);
    t4 = 0:tInt:tConstant;
    nTmp = length(t4);
    posList = [posList,posList(end) + veloTravel*t4];
    veloList = [veloList,veloTravel*ones(1,nTmp)];
    accelList = [accelList,zeros(1,nTmp)];
    jerkList = [jerkList,zeros(1,nTmp)];
    tList = [tList,t4 + tList(end)];

    tList = [tList,tList(end) + t5];
    posList = [posList,pos5];
    veloList = [veloList,velo5];
    accelList = [accelList,accel5];
    jerkList = [jerkList,jerk5];
end

%% presentation of the whole trajectory
figure;
tl1 = tiledlayout(4,1);
ax11 = nexttile;
plot(ax11,tList,posList,'LineWidth',1.5);
% posTick = posMin:posInv:posMax;
% % posTick = [posTick(1:posInitSeg),posInit,posTick(posInitSeg + 1:end)];
% posTickLabel = cell(1,length(posTick));
% posTickLabel{1} = posTick(1);
% % posTickLabel{posInitSeg + 1} = posTick(posInitSeg + 1);
% posTickLabel{end} = posTick(end);
% set(ax11,"YTick",posTick,"YTickLabel",posTickLabel,"XTickLabel",'');
grid on;
ax12 = nexttile;
plot(ax12,tList,veloList,'LineWidth',1.5);
set(ax12,"XTickLabel",'');
grid on;
ax13 = nexttile;
plot(ax13,tList,accelList,'LineWidth',1.5);
set(ax13,"XTickLabel",'');
grid on;
ax14 = nexttile;
plot(ax14,tList,jerkList,'LineWidth',1.5);
grid on;
linkaxes([ax11,ax12,ax13,ax14],'x');

% % if used to draw in Visio or PPT, then the tick labels and axis labels
% % should be removed
% xlab11 = get(ax11,'xticklabel');
% ylab11 = get(ax11,'yticklabel');
% xlab12 = get(ax12,'xticklabel');
% ylab12 = get(ax12,'yticklabel');
% xlab13 = get(ax13,'xticklabel');
% ylab13 = get(ax13,'yticklabel');
% xlab14 = get(ax14,'xticklabel');
% ylab14 = get(ax14,'yticklabel');
% while true
%     [uiIndex,uiTf] = listdlg('ListString', ...
%         {'Plot for showing','Plot for saving'}, ...
%         'InitialValue',1, ...
%         'PromptString','Select the plotting behaviour:', ...
%         'SelectionMode','single','ListSize',[100,50]);
%     if ~uiTf
%         break;
%     end
%     if uiIndex == 1
%         % show the results
%         set(ax11,'xticklabel',xlab11,'yticklabel',ylab11);
%         ylabel(ax11,'s (m)','Rotation',0);
%         set(ax12,'xticklabel',xlab12,'yticklabel',ylab12);
%         ylabel(ax12,'v (m/s)','Rotation',0);
%         set(ax13,'xticklabel',xlab13,'yticklabel',ylab13);
%         ylabel(ax13,'a (m/s^2)','Rotation',0);
%         set(ax14,'xticklabel',xlab14,'yticklabel',ylab14);
%         ylabel(ax14,'j (m/s^3)','Rotation',0);
%         xlabel(tl1,'time(s)');
%     else
%         set(ax11,'xticklabel',[],'yticklabel',[],'ylabel',[]);
%         set(ax12,'xticklabel',[],'yticklabel',[],'ylabel',[]);
%         set(ax13,'xticklabel',[],'yticklabel',[],'ylabel',[]);
%         set(ax14,'xticklabel',[],'yticklabel',[],'ylabel',[]);
%         xlabel(tl1,[]);
%     end
% end
% 
% % save the dataset
% % -------------------- select which data to save --------------------
% [dataFile,dataDir] = uiputfile({'*.csv','Comma-seperated-values file(*.csv)'; ...
%     '*.*','All files'},'Enter the file to save the trajactory data');
% if ~dataFile
%     return;
% end
% dataPath = fullfile(dataDir,dataFile);
% [~,~,fileExts] = fileparts(dataFile);
% switch fileExts
%     case ".csv"
%         writematrix([tList0',posList0'],dataPath);
%     otherwise
%         fprintf("No file saved.");
% end