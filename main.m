% MAIN — Toolkit de Dimensionamento Preliminar de Foguetões (MATLAB/Octave)
% Diogo: edita a configuração e os parâmetros abaixo conforme o teu projeto.

clear; clc; close all;
addpath('configs'); addpath('util');

%% Parâmetros de missão (exemplo)
mission.target_alt   = 200e3;     % Altitude de órbita alvo [m]
mission.inclination  = 0.0;       % [rad] — neste modelo 2D não é usado
mission.launch_lat   = deg2rad(38.65); % Latitude do local de lançamento (ex.: Lisboa ~ 38.65ºN)
mission.east_azimuth = 0;         % 0 => Este; neste 2D assumimos voo para Este

% Otimização de trajetória — limites de pesquisa
traj_bounds.t_pitch_s     = [5, 100];     % [s]
traj_bounds.pitch_kick_deg= [0.5, 12];    % [deg]
traj_bounds.kick_dur_s    = [0.5, 3.0];   % [s] duração do impulso inclinado

% Critério de corte para "órbita atingida"
mission.tol_v_ms   = 50;     % tolerância em velocidade orbital [m/s]
mission.tol_gamma  = deg2rad(2); % tolerância em ângulo de trajetória [rad]

%% Escolher configuração
% Substitui por outro ficheiro em /configs (ex.: 'vega_config', 'protonkdm3_config', 'ariane5_config')
cfg = demo_config();

%% Otimização de trajetória + bisseção da carga útil máxima
% Nota: a massa de propelente por estágio vem de cfg.stages(i).mp (edita na config)
opt_opts.verbose = true;

[result, history] = evaluate_payload_ratio(cfg, mission, traj_bounds, opt_opts);

%% Relatório
fprintf('\n===== RESULTADOS =====\n');
fprintf('Payload máximo: %.2f kg\n', result.payload_kg);
fprintf('Massa de descolagem m0: %.2f kg\n', result.m0_kg);
fprintf('Payload ratio (m_PL/m0): %.4f\n', result.payload_ratio);
fprintf('t_pitch: %.2f s | pitch_kick: %.2f deg | kick_dur: %.2f s\n', ...
    result.traj.t_pitch, rad2deg(result.traj.pitch_kick), result.traj.kick_dur);

%% Gráficos
plot_trajectory(history.best_traj);

%% Guardar resultados em MAT
save('last_run.mat', 'result', 'history');
disp('Resultados guardados em last_run.mat');
