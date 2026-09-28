function result = simulate_thesis_2014_trajectory(cfg,mass_result,opts)
%SIMULATE_THESIS_2014_TRAJECTORY Chain atmospheric phase and TPBVP.
%
% This function connects:
%   generalized mass sizing
%   -> historical vertical ascent / gravity turn
%   -> Knudsen transition (default Kn=5)
%   -> staged minimum-time free-flight TPBVP
%   -> circular-orbit target.
%
% It is a reconstruction bridge, not yet final validation of Vega/Proton.
% The atmospheric phase follows thesis equations and the free-flight phase
% uses the restored bvp4c PMP formulation. Coast phases are not yet inserted.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'trajectory_config'), opts.trajectory_config=struct(); end
if ~isfield(opts,'atmospheric_opts'), opts.atmospheric_opts=struct(); end
if ~isfield(opts,'free_flight_opts'), opts.free_flight_opts=struct(); end

hcfg=thesis_trajectory_config_from_mass_result(cfg,mass_result, ...
    opts.trajectory_config);
atm=simulate_thesis_2014_atmospheric_phase(hcfg,opts.atmospheric_opts);

result.atmospheric=atm;
result.free_flight=[];
result.orbit_reached=false;
result.transition_detected=atm.transition.detected;
result.status='Atmospheric phase completed; no Knudsen transition detected.';

if ~atm.transition.detected
    return;
end

env=earth_constants();
target_alt=cfg.mission.orbit_altitude_km*1e3;
target_v=sqrt(env.mu/(env.Re+target_alt));

% The event is the final sample of the atmospheric phase.
gamma=atm.transition.gamma_rad;
v=atm.transition.velocity_m_s;
initial.x_m=atm.x(end);
initial.y_m=atm.transition.altitude_m;
initial.vx_m_s=v*cos(gamma);
initial.vy_m_s=v*sin(gamma);
initial.mass_kg=atm.transition.mass_kg;

target.y_m=target_alt;
target.vx_m_s=target_v;
target.vy_m_s=0;

schedule=build_free_flight_schedule(hcfg.stages,atm.transition);
result.schedule=schedule;
result.initial_free_flight=initial;
result.target=target;

try
    free=thesis_staged_free_flight_tpbvp(initial,target,schedule, ...
        opts.free_flight_opts);
catch ME
    result.status=['Free-flight TPBVP did not converge: ' ME.message];
    result.free_flight_error=ME;
    return;
end

result.free_flight=free;
result.orbit_reached=free.converged && ...
    abs(free.y_m(end)-target.y_m)<=max(1,1e-6*target.y_m) && ...
    abs(free.vx_m_s(end)-target.vx_m_s)<=max(1,1e-6*target.vx_m_s) && ...
    abs(free.vy_m_s(end)-target.vy_m_s)<=1;
result.total_time_s=atm.transition.time_s+free.tf_s;
result.final_mass_kg=free.mass_kg(end);
result.free_flight_propellant_used_kg=initial.mass_kg-free.mass_kg(end);
result.status='Atmospheric Knudsen phase and staged free-flight TPBVP completed.';
result.model_status=[ ...
    '2014 trajectory reconstruction: vertical ascent + gravity turn + ', ...
    'Knudsen transition + minimum-time staged TPBVP. Coast phases and ', ...
    'end-to-end historical validation remain pending.'];
end
