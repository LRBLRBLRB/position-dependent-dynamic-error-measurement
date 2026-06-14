function pos = s_traj_pos(t0,jerk,acceMax,param,t)
%S_TRAJ_POS calculate the position of each point on the s-shape trajactory
%
% Syntax:
% 
%   pos = s_traj_pos(t0,jerk,acceMax,param,t)
%
% Description:
%
%   Calculate the position of each point on the s-shape trajactory
%
% Input Arguments:
%
%   t0,jerk,acceMax,param,t
%
% Output Arguments:
%
%   pos

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

pos = is1.*(param(1,3) + param(1,2).*(t - t0) + 1/6*jerk.*(t - t0).^3) ...
    + is2.*(param(2,3) + param(2,2).*(t - t1) + 1/2*acceMax.*(t - t1).^2) ...
    + is3.*(param(3,3) + param(3,2).*(t - t2) + 1/2*acceMax*(t - t2).^2 - 1/6*jerk.*(t - t2).^3); 
end
