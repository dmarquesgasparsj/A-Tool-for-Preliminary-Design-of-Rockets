function tests = test_parallel_boosters
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'validation'));
end

function testDirectParallelPhaseMassAccounting(testCase)
upper=500;
core=struct('mp_kg',100,'ms_kg',20,'thrust_N',10000, ...
    'Isp_s',250,'burn_time_s',100);
booster=struct('mp_kg',20,'ms_kg',5,'thrust_N',5000, ...
    'Isp_s',250,'burn_time_s',20,'count',2);
r=parallel_booster_performance(upper,core,booster);
verifyEqual(testCase,r.initial_mass_kg,670,'AbsTol',1e-12);
verifyEqual(testCase,r.mass_before_booster_jettison_kg,610, ...
    'AbsTol',1e-12);
verifyEqual(testCase,r.mass_after_booster_jettison_kg,600, ...
    'AbsTol',1e-12);
verifyEqual(testCase,r.core_propellant_burned_with_boosters_kg,20, ...
    'AbsTol',1e-12);
verifyEqual(testCase,r.core_propellant_remaining_after_boosters_kg,80, ...
    'AbsTol',1e-12);
verifyGreaterThan(testCase,r.phase0_delta_v_m_s,0);
verifyGreaterThan(testCase,r.phase1_delta_v_m_s,0);
verifyEqual(testCase,r.booster_burn_fraction_of_core,0.2, ...
    'AbsTol',1e-12);
end

function testArianeOptimumConfigurationProvenance(testCase)
cfg=ariane5_2014_parallel_config('reported_optimum');
verifyEqual(testCase,cfg.boosters.count,2);
verifyEqual(testCase,cfg.boosters.stage.thrust_N,8000e3);
verifyEqual(testCase,cfg.boosters.burn_fraction_of_core,0.25);
verifyEqual(testCase,cfg.parallel_delta_v_fractions,[.25 .49 .26], ...
    'AbsTol',1e-12);
verifyEqual(testCase,cfg.stages(1).thrust_N,1700e3);
verifyEqual(testCase,cfg.stages(2).thrust_N,58.5e3);
verifyGreaterThan(testCase,cfg.mission.delta_v_budget_m_s,8000);
verifyLessThan(testCase,cfg.mission.delta_v_budget_m_s,9000);
end

function testArianeReportedOptimumCanBeSized(testCase)
cfg=ariane5_2014_parallel_config('reported_optimum');
r=size_parallel_booster_launcher(cfg, ...
    struct('delta_v_match_tolerance_m_s',1000));
verifyGreaterThan(testCase,r.GLOW_kg,cfg.mission.payload_kg);
verifyGreaterThan(testCase,r.lower.booster_total_propellant_kg,0);
verifyGreaterThan(testCase,r.lower.booster_total_structural_kg,0);
verifyGreaterThan(testCase,r.liftoff_TW,1);
verifyEqual(testCase,r.lower.performance.booster.count,2);
verifyEqual(testCase,r.actual_ideal_total_delta_v_m_s, ...
    r.actual_booster_phase_delta_v_m_s + ...
    r.target_core_only_delta_v_m_s + r.upper_delta_v_m_s, ...
    'RelTol',1e-12);
fprintf(['ARIANE modern reported-optimum interpretation: GLOW %.1f kg, ', ...
    'T/W %.3f, booster DV error %+.1f m/s\n'], ...
    r.GLOW_kg,r.liftoff_TW,r.booster_phase_delta_v_error_m_s);
end

function testArianeBenchmarkDoesNotTuneToReference(testCase)
report=run_ariane5_2014_parallel_benchmark( ...
    struct('delta_v_match_tolerance_m_s',1000));
verifyEqual(testCase,numel(report.cases),2);
verifyEqual(testCase,report.reported_reduction_kg,84063.5, ...
    'AbsTol',1e-9);
verifyTrue(testCase,any([report.cases.success]));
end

function testSmallOptimizerKeepsBestAndClosest(testCase)
base=ariane5_2014_parallel_config('reported_optimum');
space=struct();
space.booster_thrust_N_each=[7600 8000]*1e3;
space.booster_burn_fraction_of_core=[.25 .30];
space.delta_v_fractions=[.25 .49 .26; .20 .50 .30];
r=optimize_parallel_booster_launcher(base,space,struct( ...
    'delta_v_match_tolerance_m_s',1000,'max_evaluations',20));
verifyEqual(testCase,r.evaluation_count,8);
verifyGreaterThan(testCase,r.success_count,0);
verifyFalse(testCase,isempty(r.closest_delta_v));
if r.feasible_count>0
    verifyFalse(testCase,isempty(r.best_feasible));
    verifyTrue(testCase,r.best_feasible.feasible);
end
end


function testProgrammaticParallelBoosterRunner(testCase)
cfg=ariane5_2014_parallel_config('reported_optimum');
[r,returned]=run_parallel_booster_sizing(cfg,struct( ...
    'show_plots',false,'delta_v_match_tolerance_m_s',1500));
verifyEqual(testCase,returned.name,cfg.name);
verifyGreaterThan(testCase,r.GLOW_kg,cfg.mission.payload_kg);
verifyEqual(testCase,r.configuration.name,cfg.name);
verifyEqual(testCase,r.lower.booster_count,2);
end
