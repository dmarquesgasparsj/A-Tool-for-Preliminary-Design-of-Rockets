function tests = test_historical_end_to_end
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'validation'));
addpath(fullfile(root,'util'));
end

function testCoastSegmentsAreExplicit(testCase)
v=vega_2014_trajectory_config();
tr=struct('stage_index',1, ...
    'remaining_propellant_kg',0.5*v.stages(1).mp_kg);
s=build_free_flight_schedule(v.stages,tr, ...
    struct('coast_time_s',v.coast_time_s));
types={s.segment_type};
verifyTrue(testCase,any(strcmp(types,'coast')));
verifyEqual(testCase,sum(strcmp(types,'coast')),3);
coasts=s(strcmp(types,'coast'));
verifyEqual(testCase,[coasts.duration_s],[3 3 3], ...
    'AbsTol',1e-12);
verifyEqual(testCase,[coasts.thrust_N],[0 0 0]);
end

function testVegaFixedMassThreePhaseDiagnostic(testCase)
cfg=vega_2014_trajectory_config();
opts=struct('free_flight_opts',struct( ...
    'rel_tol',1e-4,'abs_tol',1e-6,'mesh_points',41, ...
    'output_points',101,'max_nodes',12000));
r=simulate_thesis_reference_trajectory(cfg,opts);
verifyTrue(testCase,r.transition_detected);
verifyGreaterThan(testCase,r.atmospheric.transition.time_s,90);
verifyLessThan(testCase,r.atmospheric.transition.time_s,200);

fprintf(['VEGA E2E: Kn=5 %.3f s (thesis %.1f); ', ...
    'h=%.1f km; status=%s\n'], ...
    r.atmospheric.transition.time_s, ...
    cfg.reported.gravity_turn_end_time_s, ...
    r.atmospheric.transition.altitude_m/1000,r.status);
if ~isempty(r.free_flight)
    fprintf(['VEGA E2E: total %.3f s (thesis %.1f); ', ...
        'last-stage reserve %.2f%% (trajectory target %.1f%%); ', ...
        'orbit=%d\n'],r.total_time_s,cfg.reported.flight_time_s, ...
        100*r.last_stage_propellant_remaining_fraction, ...
        cfg.reported.trajectory_validation_last_stage_unburned_percent, ...
        r.orbit_reached);
    verifyTrue(testCase,isfinite(r.total_time_s));
    verifyGreaterThanOrEqual(testCase, ...
        r.last_stage_propellant_remaining_fraction,0);
end
end

function testProtonAtmosphericProvenanceModes(testCase)
ref=proton_2014_reference();
modes={'thesis_semantic','recovered_development_mass'};
for i=1:numel(modes)
    cfg=proton_2014_trajectory_config(modes{i});
    p=simulate_thesis_2014_atmospheric_phase(cfg);
    verifyTrue(testCase,p.transition.detected);
    verifyGreaterThan(testCase,p.transition.time_s,100);
    verifyLessThan(testCase,p.transition.time_s,300);
    fprintf(['PROTON %s: Kn=5 %.3f s (thesis %.1f), ', ...
        'h=%.1f km\n'],modes{i},p.transition.time_s, ...
        ref.reported.gravity_turn_end_time_s, ...
        p.transition.altitude_m/1000);
end
end

function testProtonFixedMassThreePhaseDiagnostic(testCase)
cfg=proton_2014_trajectory_config('thesis_semantic');
opts=struct('free_flight_opts',struct( ...
    'rel_tol',2e-4,'abs_tol',1e-6,'mesh_points',41, ...
    'output_points',101,'max_nodes',12000));
r=simulate_thesis_reference_trajectory(cfg,opts);
verifyTrue(testCase,r.transition_detected);
fprintf('PROTON E2E: status=%s\n',r.status);
if ~isempty(r.free_flight)
    fprintf(['PROTON E2E: total %.3f s (thesis %.1f); ', ...
        'last active-stage reserve %.2f%%; orbit=%d\n'], ...
        r.total_time_s,cfg.reported.flight_time_s, ...
        100*r.last_stage_propellant_remaining_fraction, ...
        r.orbit_reached);
    verifyTrue(testCase,isfinite(r.total_time_s));
end
end
