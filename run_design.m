function [result, history] = run_design(payload, orbit_alt)
%RUN_DESIGN Execute rocket design evaluation without GUI interaction.
%   [RESULT, HISTORY] = RUN_DESIGN(PAYLOAD, ORBIT_ALT) runs the design
%   evaluation for a desired PAYLOAD mass [kg] and target orbit altitude
%   ORBIT_ALT [km]. The routine reports feasibility, prints a summary,
%   plots the best trajectory and saves results to 'last_run.mat'.

% Housekeeping and paths
clc; close all;
addpath('configs');
addpath('util');

%% Mission parameters
mission.target_alt   = orbit_alt * 1e3; % Target orbit altitude [m]
mission.inclination  = 0.0;             % [rad] — not used in this 2D model
mission.launch_lat   = deg2rad(38.65);  % Launch site latitude (e.g., Lisbon)
mission.east_azimuth = 0;               % 0 => East; flight to the East

%% Trajectory optimization — search bounds
traj_bounds.t_pitch_s      = [5, 100];   % [s]
traj_bounds.pitch_kick_deg = [0.5, 12];  % [deg]
traj_bounds.kick_dur_s     = [0.5, 3.0]; % [s] duration of the inclined impulse

%% Orbit attainment tolerance criteria
mission.tol_v_ms  = 50;             % Orbital velocity tolerance [m/s]
mission.tol_gamma = deg2rad(2);     % Trajectory angle tolerance [rad]

%% Choose configuration
% Replace with another file in /configs if desired
cfg = demo_config();

%% Trajectory optimization + bisection of maximum payload
% Note: propellant mass per stage comes from cfg.stages(i).mp
opt_opts.verbose = true;
[result, history] = evaluate_payload_ratio(cfg, mission, traj_bounds, opt_opts);

%% Check if desired payload is achievable
if payload <= result.payload_kg
    fprintf('Desired payload %.2f kg CAN be delivered to %.0f km orbit.\n', payload, mission.target_alt/1e3);
else
    fprintf('Desired payload %.2f kg exceeds capability %.2f kg for %.0f km orbit.\n', ...
        payload, result.payload_kg, mission.target_alt/1e3);
end

%% Report
fprintf('\n===== RESULTS =====\n');
fprintf('Maximum payload: %.2f kg\n', result.payload_kg);
fprintf('Lift-off mass m0: %.2f kg\n', result.m0_kg);
fprintf('Payload ratio (m_PL/m0): %.4f\n', result.payload_ratio);
fprintf('t_pitch: %.2f s | pitch_kick: %.2f deg | kick_dur: %.2f s\n', ...
    result.traj.t_pitch, rad2deg(result.traj.pitch_kick), result.traj.kick_dur);

%% Plots
plot_trajectory(history.best_traj);

%% Save results to MAT
save('last_run.mat', 'result', 'history');
disp('Results saved to last_run.mat');
end
