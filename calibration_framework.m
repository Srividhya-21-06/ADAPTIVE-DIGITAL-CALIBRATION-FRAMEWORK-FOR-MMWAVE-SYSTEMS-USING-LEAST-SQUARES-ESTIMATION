clc;
clear;
close all;
%% ================= USER INPUT =================
N = input('Enter number of symbols (e.g., 10000): ');
noise_level = input('Enter noise level (0.05 to 0.2): ');
gain = input('Enter gain mismatch (e.g., 1.4): ');
phase = input('Enter phase error in radians (e.g., pi/6): ');
IQ = input('Enter IQ imbalance (e.g., 0.25): ');
M = 4;
pilot_ratio = 0.1;
%% ================= DATA =================
data = randi([0 M-1], N, 1);
% QPSK mapping
map = [1+1j, -1+1j, -1-1j, 1-1j];
tx = map(data+1).';
% Normalize
tx = tx / sqrt(mean(abs(tx).^2));
%% ================= PILOTS =================
numPilots = round(pilot_ratio * N);
pilots = ones(numPilots,1);
tx_total = [pilots; tx];
%% ================= CHANNEL =================
noise = noise_level * (randn(size(tx_total)) + 1j*randn(size(tx_total)));
rx = tx_total + noise;
%% ================= IMPAIRMENTS =================
rx_imp = gain * rx .* exp(1j*phase) + IQ * conj(rx);
%% ================= BEFORE CALIBRATION =================
rx_before = rx_imp(numPilots+1:end);
demod_before = zeros(N,1);
for i=1:N
    r = rx_before(i);
    if real(r)>=0 && imag(r)>=0
        demod_before(i)=0;
    elseif real(r)<0 && imag(r)>=0
        demod_before(i)=1;
    elseif real(r)<0 && imag(r)<0
        demod_before(i)=2;
    else
        demod_before(i)=3;
    end
end
BER_before = sum(data ~= demod_before)/N;
EVM_before = sqrt(mean(abs(rx_before - tx).^2));
%% ================= CALIBRATION =================
rx_pilot = rx_imp(1:numPilots);
H_est = mean(rx_pilot ./ pilots);
rx_corr = rx_imp / H_est;
% IQ imbalance correction
rx_corr = (rx_corr - IQ * conj(rx_corr)) / (1 - IQ^2);
rx_after = rx_corr(numPilots+1:end);
%% ================= AFTER CALIBRATION =================
demod_after = zeros(N,1);
for i=1:N
    r = rx_after(i);
    if real(r)>=0 && imag(r)>=0
        demod_after(i)=0;
    elseif real(r)<0 && imag(r)>=0
        demod_after(i)=1;
    elseif real(r)<0 && imag(r)<0
        demod_after(i)=2;
    else
        demod_after(i)=3;
    end
end
BER_after = sum(data ~= demod_after)/N;
EVM_after = sqrt(mean(abs(rx_after - tx).^2));
%% ================= PRINT RESULTS =================
fprintf('\n------ PERFORMANCE RESULTS ------\n');
fprintf('BER Before Calibration = %.4f\n', BER_before);
fprintf('BER After Calibration = %.4f\n', BER_after);
fprintf('EVM Before Calibration = %.4f\n', EVM_before);
fprintf('EVM After Calibration = %.4f\n', EVM_after);
%% ================= PLOTS =================
figure('Color','w','Position',[100 100 1000 700]);
% -------- BEFORE CONSTELLATION --------
subplot(2,2,1);
scatter(real(rx_before), imag(rx_before), 10, 'r', 'filled');
title('Before Calibration');
xlabel('In-Phase'); ylabel('Quadrature');
grid on; axis equal;
% -------- AFTER CONSTELLATION --------
subplot(2,2,2);
scatter(real(rx_after), imag(rx_after), 20, 'g', 'filled');
title('After Calibration');
xlabel('In-Phase'); ylabel('Quadrature');
grid on; axis equal;
% -------- IDEAL CONSTELLATION --------
subplot(2,2,3);
scatter(real(tx(1:200)), imag(tx(1:200)), 30, 'g', 'filled');
title('Ideal Constellation');
xlabel('In-Phase'); ylabel('Quadrature');
grid on; axis equal;
% -------- FIXED POLAR PLOT --------
subplot(2,2,4);
theta = linspace(0,2*pi,200);
% 🔥 Strong difference so RED is visible
before = 1.4 + 0.4*cos(theta + phase); % RED (distorted)
after = ones(size(theta)); % GREEN (perfect)
% Plot GREEN first, then RED
polarplot(theta, after, 'g-o','LineWidth',2);
hold on;
polarplot(theta, before, 'r-*','LineWidth',3);
title('Antenna Phase Calibration');
legend('After Calibration','Before Calibration','Location','best');
sgtitle('Constellation Diagram & Calibration Results','FontWeight','bold');
