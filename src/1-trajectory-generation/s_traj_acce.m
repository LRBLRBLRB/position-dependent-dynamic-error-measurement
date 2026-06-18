function acce = s_traj_acce(t0,jerk,acceMax,param,t)
%S_TRAJ_ACCE calculate the acceleration of each point on the s-shape trajactory
%
% Syntax:
% 
%   acce = s_traj_acce(t0,jerk,acceMax,param,t)
%
% Description:
%
%   Calculate the acceleration of each point on the s-shape trajactory
%
% Input Arguments:
%
%   t0,jerk,acceMax,param,t
%
% Output Arguments:
%
%   acce

t1 = t0 + param(2,1);
t2 = t0 + param(3,1);
t3 = t0 + param(4,1);

is1 = t >= t0 & t <= t1;
is2 = t > t1 & t <= t2;
is3 = t > t2 & t <= t3;

if nnz(is1 + is2 + is3 - 1)
    disp(3);
    pause;
end

acce = is1.*jerk.*(t - t0) ...
    + is2.*acceMax ...
    + is3.*(acceMax - jerk.*(t - t2)); 
end