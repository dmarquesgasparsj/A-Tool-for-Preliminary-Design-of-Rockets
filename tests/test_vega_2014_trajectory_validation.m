function tests = test_vega_2014_trajectory_validation
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'validation'));
addpath(fullfile(root,'util'));
end

function testHistoricalVegaAtmosphericSensitivity(testCase)
cfg=vega_2014_trajectory_config();
ref=vega_2014_reference();

cases={ ...
    struct('name','thesis-active-diameter','drag_reference','active_stage'), ...
    struct('name','recovered-1.9m-diameter','drag_reference','upper_stack'), ...
    struct('name','reported-m0-and-1.9m','drag_reference','upper_stack', ...
        'initial_mass_kg',ref.reported.table6_4_first_stage_m0_kg)};

times=zeros(1,numel(cases));
maxq_alt=zeros(1,numel(cases));
for i=1:numel(cases)
    opts=cases{i};
    p=simulate_thesis_2014_atmospheric_phase(cfg,opts);
    verifyTrue(testCase,p.transition.detected, ...
        sprintf('%s did not reach Kn=5',opts.name));
    verifyGreaterThan(testCase,p.transition.time_s,40);
    verifyLessThan(testCase,p.transition.time_s,200);
    verifyGreaterThan(testCase,p.transition.altitude_m,50e3);
    verifyLessThan(testCase,p.transition.altitude_m,200e3);
    verifyGreaterThan(testCase,p.max_q_altitude_m,2e3);
    verifyLessThan(testCase,p.max_q_altitude_m,25e3);

    times(i)=p.transition.time_s;
    maxq_alt(i)=p.max_q_altitude_m;
    fprintf(['VEGA-2014 %s: Kn=5 at %.3f s, h=%.1f km; ', ...
        'max-q h=%.2f km; error vs reported 97.1s = %+.3f s\n'], ...
        opts.name,p.transition.time_s,p.transition.altitude_m/1000, ...
        p.max_q_altitude_m/1000, ...
        p.transition.time_s-ref.reported.gravity_turn_end_time_s);
end

% These cases deliberately expose modelling/provenance sensitivity rather
% than selecting a diameter/mass convention because it matches the target.
verifyTrue(testCase,all(isfinite(times)));
verifyTrue(testCase,all(isfinite(maxq_alt)));
end

function testRecoveredDevelopmentGravityTurnSensitivity(testCase)
base=vega_2014_trajectory_config();
dev=vega_2014_recovered_gravity_test();

% Change only values explicitly visible in the recovered trajectory test.
cfg=base;
cfg.gravity_turn_altitude_m=dev.gravity_turn_altitude_m;
cfg.gravity_turn_seed_gamma_rad=dev.gamma0_rad;
for i=1:numel(cfg.stages)
    cfg.stages(i).mp_kg=dev.mp_kg(i);
    cfg.stages(i).Isp_s=dev.Isp_s(i);
    cfg.stages(i).thrust_N=dev.thrust_N(i);
    cfg.stages(i).burn_time_s=dev.burn_time_s(i);
end
% The recovered script uses d=1.9 m for frontal area. The recovered
% atmosphere routine also names its characteristic input diam_last, while
% the thesis text says radius. Run both interpretations.
cfg.stages(1).diameter_m=dev.aerodynamic_diameter_m;
cfg.stages(1).reference_area_m2=pi*dev.aerodynamic_diameter_m^2/4;

lengths=[dev.aerodynamic_diameter_m,dev.aerodynamic_diameter_m/2];
labels={'recovered-d-as-Kn-length','recovered-radius-as-Kn-length'};
for i=1:2
    cfg.knudsen_characteristic_length_m=lengths(i);
    opts=struct('drag_reference','active_stage', ...
        'initial_mass_kg',dev.section_initial_mass_kg(1));
    p=simulate_thesis_2014_atmospheric_phase(cfg,opts);
    verifyTrue(testCase,p.transition.detected);
    fprintf(['VEGA-2014 %s: Kn=5 at %.3f s, h=%.1f km; ', ...
        'max-q h=%.2f km; error vs thesis 97.1s = %+.3f s\n'], ...
        labels{i},p.transition.time_s,p.transition.altitude_m/1000, ...
        p.max_q_altitude_m/1000, ...
        p.transition.time_s-base.reported.gravity_turn_end_time_s);
end
end

function testVegaReferenceFixtureCarriesThesisLandmarks(testCase)
cfg=vega_2014_trajectory_config();
verifyEqual(testCase,cfg.gravity_turn_altitude_m,500);
verifyEqual(testCase,cfg.knudsen_threshold,5);
verifyEqual(testCase,cfg.knudsen_characteristic_length_m,1.3, ...
    'AbsTol',1e-12);
verifyEqual(testCase,cfg.reported.gravity_turn_end_time_s,97.1, ...
    'AbsTol',1e-12);
verifyEqual(testCase,cfg.reported.flight_time_s,357.4, ...
    'AbsTol',1e-12);
verifyEqual(testCase,cfg.reported.max_q_altitude_approx_m,9000);
end
