function [motionTable] = s_velocity_plan(ss,s,vs,ve,vm,am,jerk)
%S_VELOCITY_PLAN 规划单S型加速或减速速度曲线；七段式S型加减速曲线可理解为两个单S型相加
%
% inputs:
%   s0  initial position
%   s   final potision
%   v0  initial velocity
%   v   final velocity
%   vm  absolute value of the maximum allowed velocity
%   am  absolute value of the maximum allowed acceleration
%   j1  constant jerk during acceleration accumulating stage

% whether acce or decce
if (ve - vs) > 0
    vm = -1*vm;
    am = -1*am;
    jerk = -1*jerk;
end

% whether the uniform acce/decce stage exists
if (ve - vs)*jerk > am^2
    T1 = am/jerk;
    Ta
    T3 = am/j3;
end



end