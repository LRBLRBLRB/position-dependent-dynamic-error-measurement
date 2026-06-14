function len = s_traj_len(jerk,acceTol,veloMax)
%S_TRAJ_PLEN calculate the length for the round over s-shape trajactory
%
% Syntax:
% 
%   len = s_traj_len(jerk,acceTol,veloMax)
%
% Description:
%
%   Calculate the length for the round over s-shape trajactory.
%
% Input Arguments:
%
%   t0,jerk,acceMax,param,t
%
% Output Arguments:
%
%   len


[acceMax,param] = s_traj_para(-1*jerk,-1*acceTol,veloMax,-1*veloMax,'middle',0);

% 不知道在哪一段的时候速度降到0
% t0 = 0;
% t1 = t0 + param(2,1);
% t2 = t0 + param(3,1);
% t3 = t0 + param(4,1);
%
% velo = @(t) (t >= t0 & t <= t1).*(param(1,2) + 1/2*jerk.*(t - t0).^2) ...
%     + (t > t1 & t <= t2).*(param(2,2) + acceMax.*(t - t1)) ...
%     + (t > t2 & t <= t3).*(param(3,2) + acceMax*(t - t2) - 1/2*jerk.*(t - t2).^2); 
% 
% tLen = fzero(velo,t3/2);
% 
% len = (tLen >= t0 & tLen <= t1).*(param(1,3) + param(1,2).*(tLen - t0) + 1/6*jerk.*(tLen - t0).^3) ...
%     + (tLen > t1 & tLen <= t2).*(param(2,3) + param(2,2).*(tLen - t1) + 1/2*acceMax.*(tLen - t1).^2) ...
%     + (tLen > t2 & tLen <= t3).*(param(3,3) + param(3,2).*(tLen - t2) + 1/2*acceMax*(tLen - t2).^2 - 1/6*jerk.*(tLen - t2).^3); 

% 确定知道在中间恒加速度加速段速度降为0
tLen = param(2,1) - param(2,2)/acceMax;
len = param(2,3) + param(2,2).*(tLen - param(2,1)) + 1/2*acceMax.*(tLen - param(2,1)).^2;
end