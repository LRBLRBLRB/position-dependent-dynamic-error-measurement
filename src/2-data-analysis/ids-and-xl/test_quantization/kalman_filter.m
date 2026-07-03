function [x_estimates, P_estimates] = kalman_filter(A, H, Q, R, z, x_est, P_est)
%KALMANFILTER Kalman filter process in matrix form, for the process that
%the quantization error of velocity calculated by the measured displacement
%should be removed
%
% Inputs:
%   A       State transition (extrapolation) matrix
%   H       Observation matrix
%   Q       Covariance matrix of process noise
%   R       Covariance matrix of measurement moise
%   z       The measured displacements
%   x_est   Initial estimation of displacement and velocity
%   P_est   Initial estimation of error covariance

    N = length(z);
    x_estimates = zeros(2, N);
    P_estimates = zeros(2, 2, N);
    for k = 1:N
        % Prediction
        x_pred = A * x_est;
        P_pred = A * P_est * A' + Q;
        % Update
        K = P_pred * H' / (H * P_pred * H' + R);
        x_est = x_pred + K * (z(k) - H * x_pred);
        P_est = (eye(2) - K * H) * P_pred;
        % save estimation results
        x_estimates(:, k) = x_est;
        P_estimates(:, :, k) = P_est;
    end
end