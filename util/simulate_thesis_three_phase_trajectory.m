function traj = simulate_thesis_three_phase_trajectory(traj_cfg,mission,traj_params,payload_mass,opts)
%SIMULATE_THESIS_THREE_PHASE_TRAJECTORY Atmospheric GT + Kn switch + TPBVP.
%
% Phase 1/2:
%   vertical ascent followed by zero-lift gravity turn, integrated until
%   the thesis transition criterion Kn = 5.
%
% Phase 3:
%   minimum-time free flight using the thesis state/costate formulation,
%   generalized in 2026 to a fixed remaining serial-stage propulsion
%   schedule.
%
% This function is the first end-to-end reconstruction of the thesis
% three-phase trajectory architecture. It still uses the modern spherical
% atmospheric equations and a constant-gravity local-Cartesian TPBVP after
% transition; those modelling boundaries are reported explicitly.

if nargin<5 || isempty(opts), opts=struct(); end
if ~isfield(opts,'free_flight'), opts.free_flight=struct(); end
if ~isfield(mission,'tol_v_ms'), mission.tol_v_ms=50; end
if ~isfield(mission,'tol_gamma'), mission.tol_gamma=deg2rad(2); end

env=earth_constants();
atmo=propagate_to_knudsen_transition( ...
    traj_cfg,mission,traj_params,payload_mass);

traj.atmospheric=atmo;
traj.transition=atmo.transition;
traj.free_flight=[];
traj.schedule=[];
traj.completed=false;
traj.orbit_reached=false;
traj.failure_reason='';

if ~atmo.transition.detected
    traj.failure_reason='Knudsen transition was not reached before powered ascent ended.';
    traj.total_time_s=atmo.t(end);
    traj.losses=atmo.losses;
    return;
end

schedule=remaining_propulsion_schedule(traj_cfg,atmo);
traj.schedule=schedule;
xtr=atmo.transition.state;

% Convert the transition state from polar to the thesis local Cartesian
% free-flight coordinates. A constant vertical offset would not change the
% TPBVP equations, so altitude is used as y.
initial.x_m=xtr(1)*xtr(2);
initial.y_m=xtr(1)-env.Re;
initial.vx_m_s=xtr(4);
initial.vy_m_s=xtr(3);
initial.mass_kg=xtr(5);

target.y_m=mission.target_alt;
target.vx_m_s=sqrt(env.mu/(env.Re+mission.target_alt));
target.vy_m_s=0;

if ~isfield(opts.free_flight,'g_m_s2')
    opts.free_flight.g_m_s2=env.g0*(env.Re/xtr(1))^2;
end
if ~isfield(opts.free_flight,'tf_guess_s')
    available=sum([schedule.duration_s]);
    % Use kinematic horizontal-velocity demand to choose a conservative
    % starting guess while remaining strictly inside the available burn.
    dvx=max(0,target.vx_m_s-initial.vx_m_s);
    first_acc=schedule(1).thrust_N/max(initial.mass_kg,eps);
    kinematic=max(1,dvx/max(first_acc,eps));
    opts.free_flight.tf_guess_s=min(0.8*available, ...
        max(0.25*available,kinematic));
end

try
    free=thesis_staged_free_flight_tpbvp( ...
        initial,target,schedule,opts.free_flight);
catch ME
    traj.failure_reason=sprintf('TPBVP free-flight solve failed: %s',ME.message);
    traj.total_time_s=atmo.transition.time_s;
    traj.losses=atmo.losses;
    traj.free_flight_error_identifier=ME.identifier;
    return;
end
traj.free_flight=free;

% Free-flight gravity loss follows the thesis definition integral(g sinγ dt).
speed=hypot(free.vx_m_s,free.vy_m_s);
gravity_rate=free.g_m_s2*free.vy_m_s./max(speed,eps);
gravity_free=trapz(free.t_s,gravity_rate);

traj.losses.drag_m_s=atmo.losses.drag_m_s;
traj.losses.gravity_atmospheric_m_s=atmo.losses.gravity_m_s;
traj.losses.gravity_free_flight_m_s=gravity_free;
traj.losses.gravity_m_s=atmo.losses.gravity_m_s+gravity_free;
traj.losses.total_m_s=traj.losses.drag_m_s+traj.losses.gravity_m_s;
traj.total_time_s=atmo.transition.time_s+free.tf_s;

vf=hypot(free.vx_m_s(end),free.vy_m_s(end));
gammaf=atan2(free.vy_m_s(end),free.vx_m_s(end));
v_circ=target.vx_m_s;
traj.orbit.altitude_m=free.y_m(end);
traj.orbit.velocity_ms=vf;
traj.orbit.gamma_rad=gammaf;
traj.orbit.circular_velocity_ms=v_circ;
traj.orbit.velocity_error_ms=abs(vf-v_circ);
traj.orbit.gamma_error_rad=abs(gammaf);
traj.orbit.altitude_error_m=abs(free.y_m(end)-mission.target_alt);
traj.orbit.reached=free.converged && ...
    traj.orbit.altitude_error_m<=max(1,1e-6*max(mission.target_alt,1)) && ...
    traj.orbit.velocity_error_ms<=mission.tol_v_ms && ...
    traj.orbit.gamma_error_rad<=mission.tol_gamma;

traj.completed=free.converged;
traj.orbit_reached=traj.orbit.reached;
traj.final_mass_kg=free.mass_kg(end);
traj.model_status=[ ...
    'Three-phase trajectory reconstruction: spherical powered atmosphere ', ...
    'to Kn=5, then constant-gravity local-Cartesian minimum-time TPBVP ', ...
    'with a fixed serial propulsion schedule.'];
end
