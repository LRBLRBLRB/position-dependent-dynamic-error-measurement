%% ============================================================
%  等间隔采样的 jerk-limited 位移轨迹
%  单位：
%    t : s
%    x : mm
%    v : mm/s
%    a : mm/s^2
%    j : mm/s^3
%
%  约束：
%    jerk = 40 m/s^3 = 40000 mm/s^3
%    amax = 3  m/s^2 = 3000  mm/s^2
%
%  说明：
%    1) 全局时间轴严格等间隔
%    2) 每一段非零位移都按"静止->静止"的S曲线生成
%    3) 段内自动包含：加加速 / 匀加速 / 减加速 / 匀速 / ...
%    4) 零位移段为驻留段
%% ============================================================
clear; clc;
cd(fileparts(mfilename('fullpath'))); close all;

%% ---------- 参数 ----------
Jmax = 40e3;   % 40 m/s^3 = 40000 mm/s^3
Amax = 3e3;    % 3  m/s^2 = 3000  mm/s^2
dt   = 0.001;  % 等间隔采样周期，单位 s

%% ---------- 节点（按你原图近似给出，可自行修改） ----------
% 每两个相邻节点之间生成一段轨迹
tNode = [ ...
    0.0  7.4 ...
    9.8 12.2 14.6 17.0 19.4 21.8 ...
    22.5 23.2 23.9 24.6 25.3 26.0 ...
    28.6 ...
    31.1 33.5 35.8 38.4 40.9 43.4 ...
    44.0 44.6 45.2 45.8 46.4 47.0 ...
    50.0 ...
    52.4 54.8 57.4 59.8 62.3 64.7 ...
    65.3 65.9 66.5 67.1 67.9 ...
    74.0 77.5];

xNode = [ ...
       0    0 ...
    -200    0 -200    0 -200    0 ...
    -200    0 -200    0 -200    0 ...
   -1500 ...
   -1700 -1500 -1700 -1500 -1700 -1500 ...
   -1700 -1500 -1700 -1500 -1700 -1500 ...
   -3000 ...
   -3200 -3000 -3200 -3000 -3200 -3000 ...
   -3200 -3000 -3200 -3000 -3200 ...
       0    0];

if length(tNode) ~= length(xNode)
    error('tNode 和 xNode 长度必须一致');
end

if any(diff(tNode) <= 0)
    error('tNode 必须严格递增');
end

%% ---------- 全局等间隔时间轴 ----------
tEnd = tNode(end);
N = round(tEnd / dt) + 1;
theo_t = (0:N-1) * dt;

theo_disp = zeros(1, N);
v = zeros(1, N);
a = zeros(1, N);

%% ---------- 逐段生成 ----------
for k = 1:length(tNode)-1
    t0 = tNode(k);
    t1 = tNode(k+1);
    Tseg = t1 - t0;
    Dseg = xNode(k+1) - xNode(k);

    if k < length(tNode)-1
        idx = (theo_t >= t0) & (theo_t < t1);
    else
        idx = (theo_t >= t0) & (theo_t <= t1 + 1e-12);
    end

    tau = theo_t(idx) - t0;   % 该段内的局部时间

    if abs(Dseg) < 1e-12
        % 驻留段
        theo_disp(idx) = xNode(k);
        v(idx) = 0;
        a(idx) = 0;
    else
        prof = plan_scurve_fixed_time(Dseg, Tseg, Jmax, Amax);
        [xLoc, vLoc, aLoc] = sample_scurve_profile(tau, prof);

        theo_disp(idx) = xNode(k) + xLoc;
        v(idx) = vLoc;
        a(idx) = aLoc;
    end
end

%% ---------- 输出理论值 ----------
theoryValue = [theo_t(:), theo_disp(:)];   % 第一列时间，第二列位移

disp('前 20 个等间隔理论点 [t(s), x(mm)]：');
disp(theoryValue(1:min(20,size(theoryValue,1)), :));

% 如需导出：
save theo_path.mat theo_t theo_disp;

%% ---------- 绘图 ----------
figure('Color','w');
plot(theo_t, theo_disp, 'b-', 'LineWidth', 1.2); hold on;
plot(tNode, xNode, 'ko', 'MarkerSize', 4, 'LineWidth', 1);
grid on;
xlabel('Time (s)');
ylabel('Displacement (mm)');
title('Uniformly Sampled Theoretical Displacement Curve');

figure('Color','w');
plot(theo_t, v, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Velocity (mm/s)');
title('Analytical Velocity on Uniform Time Grid');

figure('Color','w');
plot(theo_t, a, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Acceleration (mm/s^2)');
title('Analytical Acceleration on Uniform Time Grid');

%% ============================================================
%                       局部函数
%% ============================================================

function prof = plan_scurve_fixed_time(D, T, J, A)
% 给定：
%   D : 位移
%   T : 总时间
%   J : 最大跃度
%   A : 最大加速度
%
% 生成对称的 rest-to-rest S 曲线：
%   +J, 0, -J, 0, -J, 0, +J
%
% 返回：
%   prof.dur   : 7段持续时间
%   prof.tb    : 各段边界时间
%   prof.jerk  : 各段jerk
%   prof.xb    : 各段起点位移
%   prof.vb    : 各段起点速度
%   prof.ab    : 各段起点加速度

    sgn = sign(D);
    Dabs = abs(D);

    if Dabs < 1e-12
        prof.dur  = zeros(1,7);
        prof.tb   = zeros(1,8);
        prof.jerk = zeros(1,7);
        prof.xb   = zeros(1,7);
        prof.vb   = zeros(1,7);
        prof.ab   = zeros(1,7);
        return;
    end

    % 最短可行时间
    [Tmin, Vp_hi] = get_min_time_and_peak_v(Dabs, J, A);

    if T < Tmin - 1e-10
        error('某段时间过短，不可实现：D=%.6f mm, T=%.6f s, Tmin=%.6f s', D, T, Tmin);
    end

    % 用二分法求满足"位移D、时间T"的峰值速度 Vp
    vlo = max(Dabs / T, 1e-12);
    vhi = Vp_hi;

    for iter = 1:100
        vmid = 0.5 * (vlo + vhi);
        Treq = calc_total_time_given_peak_v(vmid, Dabs, J, A);

        if Treq > T
            vlo = vmid;
        else
            vhi = vmid;
        end
    end

    Vp = vhi;

    % 各相时间
    [tj, ta, tv] = get_phase_times_from_peak_v(Vp, Dabs, J, A);

    dur = [tj, ta, tj, tv, tj, ta, tj];
    tb  = [0, cumsum(dur)];
    jerk = sgn * [J, 0, -J, 0, -J, 0, J];

    % 预计算每一相开始时的状态
    xb = zeros(1,7);
    vb = zeros(1,7);
    ab = zeros(1,7);

    for p = 1:6
        h = dur(p);
        jp = jerk(p);

        xb(p+1) = xb(p) + vb(p)*h + 0.5*ab(p)*h^2 + (1/6)*jp*h^3;
        vb(p+1) = vb(p) + ab(p)*h + 0.5*jp*h^2;
        ab(p+1) = ab(p) + jp*h;
    end

    prof.dur  = dur;
    prof.tb   = tb;
    prof.jerk = jerk;
    prof.xb   = xb;
    prof.vb   = vb;
    prof.ab   = ab;
    prof.D    = D;
    prof.T    = T;
end

function [x, v, a] = sample_scurve_profile(tau, prof)
% 在给定局部时间 tau 上，对 S 曲线做解析采样
% tau 必须落在 [0, T] 内

    x = zeros(size(tau));
    v = zeros(size(tau));
    a = zeros(size(tau));

    tb   = prof.tb;
    jerk = prof.jerk;
    xb   = prof.xb;
    vb   = prof.vb;
    ab   = prof.ab;

    for p = 1:7
        if p < 7
            mask = (tau >= tb(p)) & (tau < tb(p+1));
        else
            mask = (tau >= tb(p)) & (tau <= tb(p+1) + 1e-12);
        end

        if ~any(mask)
            continue;
        end

        h = tau(mask) - tb(p);
        jp = jerk(p);

        x(mask) = xb(p) + vb(p).*h + 0.5*ab(p).*h.^2 + (1/6)*jp.*h.^3;
        v(mask) = vb(p) + ab(p).*h + 0.5*jp.*h.^2;
        a(mask) = ab(p) + jp.*h;
    end

    % 尾点修正
    if ~isempty(tau)
        tailMask = abs(tau - prof.T) < 1e-12;
        x(tailMask) = prof.D;
        v(tailMask) = 0;
        a(tailMask) = 0;
    end
end

function [Tmin, Vp] = get_min_time_and_peak_v(D, J, A)
% 求在 jerk / accel 约束下，完成位移 D 的最短时间及对应峰值速度

    Dcrit = 2 * A^3 / J^2;

    if D <= Dcrit
        % 达不到最大加速度：三角加速度型
        tj   = (D / (2 * J))^(1/3);
        Vp   = J * tj^2;
        Tmin = 4 * tj;
    else
        % 能达到最大加速度，但最短时间下无匀速段
        % D = 2*A^3/J^2 + 3*A^2/J*ta + A*ta^2
        b  = 3 * A / J;
        c  = 2 * A^2 / J^2 - D / A;
        ta = (-b + sqrt(b^2 - 4*c)) / 2;

        Vp   = A^2 / J + A * ta;
        Tmin = 4 * A / J + 2 * ta;
    end
end

function Treq = calc_total_time_given_peak_v(Vp, D, J, A)
    [tj, ta, tv] = get_phase_times_from_peak_v(Vp, D, J, A);
    Treq = 4*tj + 2*ta + tv;
end

function [tj, ta, tv] = get_phase_times_from_peak_v(Vp, D, J, A)
% 对给定峰值速度 Vp，求相应相位时间

    if Vp >= A^2 / J
        % 能达到 Amax
        tj = A / J;
        ta = Vp / A - A / J;

        D_no_cruise = 2 * A^3 / J^2 + 3 * A^2 * ta / J + A * ta^2;
        tv = (D - D_no_cruise) / Vp;
    else
        % 达不到 Amax：三角加速度型
        tj = sqrt(Vp / J);
        ta = 0;

        D_no_cruise = 2 * J * tj^3;
        tv = (D - D_no_cruise) / Vp;
    end

    if tv < 0 && abs(tv) < 1e-10
        tv = 0;
    end
end