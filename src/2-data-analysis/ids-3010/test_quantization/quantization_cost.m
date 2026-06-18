function cost = quantization_cost(dt,displacement,velocity,dispMeaSquare)
%QUANTIZATION_OBJECTIVE 滤除量化噪声的目标函数计算
%   根据滤波后的序列，计算目标函数值，与滤波方式无关
%
% Inputs:
%   dt              time interval of the signal
%   displacement    signal sequence
%   velocity        velocity that is filtered
%   lambda          the importance of smoothness, within [0,1]
%   quantizationLevel 您的传感器量化步长

% 计算估计位移和测量位移之间的残差并标准化
dispMse = mean((z - displacement).^2/dispMeaSquare);

% 计算速度的变化率（加速度）的平方和，作为平滑性的指标
veloMeasure = diff(z) / dt;
veloEstimate = velocity(2:end); % 对齐长度
quantizationLevel = dt;
veloNoiseVar = (quantizationLevel / dt)^2 / 12; % 量化噪声方差
veloRes = veloEstimate - veloMeasure;
veloResMse = mean((veloRes.^2) / veloNoiseVar); % 速度残差均方值

% lambda
% 计算量化噪声方差
sigma_quant_squared = (quantizationLevel^2) / 12; ？？？
sigma_velocity_noise_squared = 2 * sigma_quant_squared / dt^2;% 计算速度噪声方差（由于差分过程，噪声方差会增加）
lambda = dispMeaSquare / sigma_velocity_noise_squared;% 计算 Lambda

% 计算目标函数的加权损失值
cost = (1 - lambda)*dispMse + lambda*veloResMse;

end