function fourier_smoothness(t,x)
%FOURIER_SMOOTHNESS 此处显示有关此函数的摘要
%   此处显示详细说明
% 计算信号的傅里叶变换
N = length(x);
Fs = 1 / mean(diff(t));  % 采样频率
f = (0:N-1)*(Fs/N);      % 频率轴

% 执行傅里叶变换
Y = fft(x);

lowFreqCutoff = 2;  % 设定低频截止点，比如选取0-2Hz的频率作为低频部分

% 对低频部分进行保留，高频部分抑制
Y_filtered = Y;
Y_filtered(f > lowFreqCutoff) = 0;

% 反向傅里叶变换，得到滤波后的位移信号
x_filtered = ifft(Y_filtered, 'symmetric');

% 绘制原始信号与低频滤波后信号
figure;
plot(t, x, 'b-', 'DisplayName', '原始位移');
hold on;
plot(t, x_filtered, 'r-', 'DisplayName', '低频滤波后位移');
xlabel('时间 (s)');
ylabel('位移 (mm)');
legend;
title('原始位移与低频滤波后位移信号对比');
end