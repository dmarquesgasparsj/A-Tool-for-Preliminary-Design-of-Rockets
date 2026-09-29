function result = simulate_thesis_reference_trajectory(hcfg,opts)
%SIMULATE_THESIS_REFERENCE_TRAJECTORY Full three-phase fixed-mass validation.
%
% HCFG is a historical trajectory fixture containing exact stage masses,
% burn times, diameters and target_altitude_m. This bypasses the modern
% mass model so trajectory validation can be separated from mass sizing.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'atmospheric_opts'), opts.atmospheric_opts=struct(); end
if ~isfield(opts,'free_flight_opts'), opts.free_flight_opts=struct(); end
if ~isfield(hcfg,'target_altitude_m')
    error('simulate_thesis_reference_trajectory:Target', ...
        'Historical fixture requires target_altitude_m.');
end

atm=simulate_thesis_2014_atmospheric_phase(hcfg,opts.atmospheric_opts);
result.atmospheric=atm;
result.transition_detected=atm.transition.detected;
result.free_flight=[];
result.orbit_reached=false;
result.status='No Knudsen transition detected.';
if ~atm.transition.detected, return; end

env=earth_constants();
target.y_m=hcfg.target_altitude_m;
target.vx_m_s=sqrt(env.mu/(env.Re+hcfg.target_altitude_m));
target.vy_m_s=0;

v=atm.transition.velocity_m_s;
gamma=atm.transition.gamma_rad;
initial.x_m=atm.x(end);
initial.y_m=atm.transition.altitude_m;
initial.vx_m_s=v*cos(gamma);
initial.vy_m_s=v*sin(gamma);
initial.mass_kg=atm.transition.mass_kg;

sopts=struct();
if isfield(hcfg,'coast_time_s'), sopts.coast_time_s=hcfg.coast_time_s; end
schedule=build_free_flight_schedule(hcfg.stages,atm.transition,sopts);
result.schedule=schedule;
result.initial_free_flight=initial;
result.target=target;

try
    free=thesis_staged_free_flight_tpbvp(initial,target,schedule, ...
        opts.free_flight_opts);
catch ME
    result.status=['Free-flight TPBVP did not converge: ' ME.message];
    result.free_flight_error_identifier=ME.identifier;
    return;
end

result.free_flight=free;
result.total_time_s=atm.transition.time_s+free.tf_s;
result.final_mass_kg=free.mass_kg(end);
result.orbit_reached=free.converged && ...
    abs(free.y_m(end)-target.y_m)<=max(1,1e-6*target.y_m) && ...
    abs(free.vx_m_s(end)-target.vx_m_s)<=max(1,1e-6*target.vx_m_s) && ...
    abs(free.vy_m_s(end))<=1;

N=numel(hcfg.stages);
last_available=0; last_used=0;
for k=1:numel(schedule)
    if schedule(k).source_stage_index==N && schedule(k).mdot_kg_s>0
        last_available=last_available+ ...
            schedule(k).mdot_kg_s*schedule(k).duration_s;
        last_used=last_used+free.segment_propellant_used_kg(k);
    end
end
result.last_stage_propellant_available_kg=last_available;
result.last_stage_propellant_used_kg=last_used;
result.last_stage_propellant_remaining_kg=max(0,last_available-last_used);
result.last_stage_propellant_remaining_fraction= ...
    result.last_stage_propellant_remaining_kg/hcfg.stages(end).mp_kg;
result.status='Historical three-phase trajectory completed.';
end
