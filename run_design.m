function [result, history] = run_design(payload, mission)
%RUN_DESIGN Execute rocket design evaluation without GUI interaction.
%   [RESULT, HISTORY] = RUN_DESIGN(PAYLOAD, MISSION) runs the design
%   evaluation for a desired PAYLOAD mass [kg] and mission structure
%   MISSION (requires subfield .orbit). The routine reports feasibility,
%   prints a summary, plots the best trajectory and saves results to
%   'last_run.mat'.

% Housekeeping and paths
clc; close all;
addpath('configs');
addpath('util');

%% Mission parameters (defaults)
if ~isfield(mission, 'inclination'),  mission.inclination  = 0.0;             end % [rad]
if ~isfield(mission, 'launch_lat'),   mission.launch_lat   = deg2rad(38.65);  end % [rad]
if ~isfield(mission, 'east_azimuth'), mission.east_azimuth = 0;               end

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
orbit_desc = describe_orbit(mission.orbit);
if payload <= result.payload_kg
    fprintf('Desired payload %.2f kg CAN be delivered to %s orbit.\n', ...
        payload, orbit_desc);
else
    fprintf(['Desired payload %.2f kg exceeds capability %.2f kg for %s ', ...
        'orbit.\n'], payload, result.payload_kg, orbit_desc);
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

function desc = describe_orbit(orbit)
switch lower(orbit.type)
    case 'circular'
        desc = sprintf('%.0f km circular', orbit.altitude_km);
    case {'elliptic','elliptical'}
        desc = sprintf('%.0f x %.0f km elliptical', ...
            orbit.periapsis_km, orbit.apoapsis_km);
    otherwise
        desc = 'specified';
end
end

