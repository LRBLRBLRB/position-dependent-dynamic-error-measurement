function [acceMax,param] = s_traj_para(jerk,acceTol,veloS,veloE,sType,pos)
%S_TRAJ_PARA generate a single s-shaped acceleration/decceleration process
%
% Syntax:
% 
%   [acceMax,param] = s_traj_para(jerk,acceTol,veloS,veloE,sType,pos)
%
% Description:
%
%   Generate a single s-shaped acceleration/decceleration process, while
%   calculating the corresponding parameters
%
% Input Arguments:
%
%   jerk,acceTol,veloS,veloE,sType,pos
%
% Output Arguments:
%
%   acceMax - maximum acceleration in the S-shaped profile
%   param - the parameters of the S-shaped profile, containing: 
%       [T0,V0,S0; T1,V1,S1; T1 + T2,V2,S2; T1 + T2 + T3,V3,S3]

% judge whether T2 exists
T2 = (veloE - veloS - acceTol^2/jerk)/acceTol;
if T2 >= 0
    % T2 exists
    acceMax = acceTol;
    T1 = acceMax/jerk;
    T3 = T1;
else
    % T2 doesn't exist
    T2 = 0;
    acceMax = sqrt((veloE - veloS)*jerk);
    T1 = acceMax/jerk;
    T3 = T1;
end
% characteristic parameters calculation: T, v, s of each segment
velo1 = veloS + 0.5*jerk*T1^2;
velo2 = velo1 + acceMax*T2;
velo3 = velo2 + acceMax*T3 - 0.5*jerk*T3^2;
if abs(velo3 - veloE) > 1e-3
    disp(1);
    pause;
end
switch sType
    case 'first'
        pos0 = pos;
        pos1 = pos0 + veloS*T1 + 1/6*jerk*T1^3;
        pos2 = pos1 + velo1*T2 + 1/2*acceMax*T2^2;
        pos3 = pos2 + velo2*T3 + 1/2*acceMax*T3^2 - 1/6*jerk*T3^3;
    case 'final'
        pos3 = pos;
        pos2 = pos3 - velo2*T3 - 1/2*acceMax*T3^2 + 1/6*jerk*T3^3;
        pos1 = pos2 - velo1*T2 - 1/2*acceMax*T2^2;
        pos0 = pos1 - veloS*T1 - 1/6*jerk*T1^3;
    otherwise % 测试！！！四个边界都定了，是否矛盾？而且这里给定的pos应该是最外侧的位置而不是初始位置
        pos0 = pos; % -------------------------------------------改边界条件-------------------------------------------
        pos1 = pos0 + veloS*T1 + 1/6*jerk*T1^3;
        pos2 = pos1 + velo1*T2 + 1/2*acceMax*T2^2;
        pos3 = pos2 + velo2*T3 + 1/2*acceMax*T3^2 - 1/6*jerk*T3^3;
        if abs(pos3 - pos) > 1e-3
            disp(2);
            pause;
        end
end
param = [0, veloS, pos0;
    T1, velo1, pos1;
    T1 + T2, velo2, pos2;
    T1 + T2 + T3, veloE, pos3];
end