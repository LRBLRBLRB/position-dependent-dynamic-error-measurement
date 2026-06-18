% 示例信号
% fs = 1000; % 采样频率
% t = 0:1/fs:1; % 时间向量
% clean_signal = sin(2*pi*50*t); % 理想信号
% noise = randn(size(t)) * 0.5; % 添加高斯噪声
% noisy_signal = clean_signal + noise; % 带噪信号

% 设计一个简单的低通滤波器
% fc = 100; % 截止频率
% [b, a] = butter(5, fc/(fs/2)); % 5阶巴特沃斯滤波器
% filtered_signal = filtfilt(b, a, noisy_signal); % 进行滤波

% 计算信号功率和噪声功率
signal_power = bandpower(noisy_signal) - bandpower(noise);
filtered_noise = noisy_signal - filtered_signal; % 估算滤波后的噪声
noise_power = bandpower(filtered_noise);

% 计算 SNR
snr_before = 10 * log10(signal_power / noise_power);
disp(['SNR Before Filtering: ', num2str(snr_before), ' dB']);

filtered_signal_power = bandpower(filtered_signal);
filtered_noise_power = bandpower(filtered_signal - clean_signal);
snr_after = 10 * log10(filtered_signal_power / filtered_noise_power);
disp(['SNR After Filtering: ', num2str(snr_after), ' dB']);

%% FFT
fs = 10000;
noisy_signal = idsData.velo;
filtered_signal = idsData.velo_filtered;

% 计算频谱
N = length(noisy_signal);
f = (0:N-1)*(fs/N); % 频率向量

% 计算 FFT
noisy_signal_fft = abs(fft(noisy_signal));
filtered_signal_fft = abs(fft(filtered_signal));

% 绘制频谱
figure;
subplot(2,1,1);
plot(f, noisy_signal_fft);
title('FFT of Noisy Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');

subplot(2,1,2);
plot(f, filtered_signal_fft);
title('FFT of Filtered Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 200]); % 限制显示频率范围


%% residual

% 计算残差
residual = noisy_signal - filtered_signal;

% 计算均方误差
mse = mean(residual.^2);
disp(['Mean Squared Error (MSE): ', num2str(mse)]);

%% 时域特征分析
% 计算均值和标准差
original_mean = mean(noisy_signal);
original_std = std(noisy_signal);
filtered_mean = mean(filtered_signal);
filtered_std = std(filtered_signal);

disp(['Original Signal Mean: ', num2str(original_mean)]);
disp(['Original Signal Std: ', num2str(original_std)]);
disp(['Filtered Signal Mean: ', num2str(filtered_mean)]);
disp(['Filtered Signal Std: ', num2str(filtered_std)]);

%% 