function velo = s_traj_velo(t0,jerk,acceMax,param,t)
%S_TRAJ_VELO calculate the velocity of each point on the s-shape trajactory
%
% Syntax:
% 
%   velo = s_traj_velo(t0,jerk,acceMax,param,t)
%
% Description:
%
%   Calculate the velocity of each point on the s-shape trajactory
%
% Input Arguments:
%
%   t0,jerk,acceMax,param,t
%
% Output Arguments:
%
%   velo

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

velo = is1.*(param(1,2) + 1/2*jerk.*(t - t0).^2) ...
    + is2.*(param(2,2) + acceMax.*(t - t1)) ...
    + is3.*(param(3,2) + acceMax*(t - t2) - 1/2*jerk.*(t - t2).^2); 
end