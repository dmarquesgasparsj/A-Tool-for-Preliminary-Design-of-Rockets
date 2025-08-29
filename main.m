% MAIN — Preliminary Rocket Design Toolkit (MATLAB/Octave)
% Adjust the configuration and parameters below as needed.

clear; clc; close all;
addpath('configs'); addpath('util');

% Ask user for payload and orbit via GUI
prompt   = {'Desired payload mass [kg]', 'Target orbit altitude [km]'};
dlgtitle = 'Mission setup';
definput = {'1000', '200'};
valid_inputs = false;
while ~valid_inputs
    answer = inputdlg(prompt, dlgtitle, 1, definput);
    if isempty(answer)
        error('User cancelled input dialog.');
    end
    user_payload  = str2double(answer{1});
    user_orbit_km = str2double(answer{2});
    if isnan(user_payload) || isnan(user_orbit_km)
        uiwait(errordlg('Input must be numeric.', 'Invalid input'));
        definput = answer;
        continue;
    end
    if user_payload <= 0 || user_orbit_km <= 0
        uiwait(errordlg('Values must be positive.', 'Invalid input'));
        definput = answer;
        continue;
    end
    valid_inputs = true;
end

%% Mission parameters
mission.target_alt   = user_orbit_km * 1e3; % Target orbit altitude [m]
mission.inclination  = 0.0;       % [rad] — not used in this 2D model
mission.launch_lat   = deg2rad(38.65); % Launch site latitude (e.g., Lisbon ~ 38.65ºN)
mission.east_azimuth = 0;         % 0 => East; in this 2D model we assume flight to the East

% Trajectory optimization — search bounds
traj_bounds.t_pitch_s     = [5, 100];     % [s]
traj_bounds.pitch_kick_deg= [0.5, 12];    % [deg]
traj_bounds.kick_dur_s    = [0.5, 3.0];   % [s] duration of the inclined impulse

% Orbit attainment tolerance criteria
mission.tol_v_ms   = 50;     % orbital velocity tolerance [m/s]
mission.tol_gamma  = deg2rad(2); % trajectory angle tolerance [rad]

%% Choose configuration
% Replace with another file in /configs (e.g., 'vega_config', 'protonkdm3_config', 'ariane5_config')
cfg = demo_config();

%% Trajectory optimization + bisection of maximum payload
% Note: propellant mass per stage comes from cfg.stages(i).mp (edit in the config)
opt_opts.verbose = true;

[result, history] = evaluate_payload_ratio(cfg, mission, traj_bounds, opt_opts);

% Check if desired payload is achievable
if user_payload <= result.payload_kg
    fprintf('Desired payload %.2f kg CAN be delivered to %.0f km orbit.\n', user_payload, mission.target_alt/1e3);
else
    fprintf('Desired payload %.2f kg exceeds capability %.2f kg for %.0f km orbit.\n', user_payload, result.payload_kg, mission.target_alt/1e3);
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
