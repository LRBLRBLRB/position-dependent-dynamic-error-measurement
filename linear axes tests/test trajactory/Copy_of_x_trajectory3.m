% 修复了在经过x=0的地方速度会在0附近做加减速的bug
close all
clear
clc

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

tNode =    [0 7.34007 9.62392 12.1225 14.576 17.0353 19.4768 21.9281]
dispNode = [0       0    -200       0   -200       0    -200       0]