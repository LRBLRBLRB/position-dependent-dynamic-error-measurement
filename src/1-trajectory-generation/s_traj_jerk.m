function jerks = s_traj_jerk(t0,jerk,param,t)
%S_TRAJ_JERK calculate the jerk of each point on the s-shape trajactory
%
% Syntax:
% 
%   jerks = s_traj_velo(t0,jerk,param,t)
%
% Description:
%
%   Calculate the jerk of each point on the s-shape trajactory
%
% Input Arguments:
%
%   t0,jerk,param,t
%
% Output Arguments:
%
%   jerks

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

jerks = is1.*jerk ...
    + is3.*(-1).*jerk; 
end