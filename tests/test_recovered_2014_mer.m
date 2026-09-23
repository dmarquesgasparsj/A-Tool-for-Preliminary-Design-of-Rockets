function tests = test_recovered_2014_mer
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
end

function testTwoStageSourceSpecificMER(testCase)
% Exact active equations from mass_model_n_2.m, second stage.
stage.thrust_N = 70000;
stage.mixture_ratio_OF = 3.8;
stage.nozzle_area_ratio = 20;
masses.mp_kg = 2200;
masses.payload_above_kg = 1000;
masses.section_initial_mass_kg = 3500;
mer = thesis_legacy_mer(stage,masses,2,2);
ox = 2200*3.8/4.8;
fuel = 2200/4.8;
tank = 0.0107*ox + 0.128*fuel;
engine = (7.81e-4*70000+3.37e-5*70000*sqrt(20)+59)*0.2;
expected = tank + 10*3500^0.361 + 2.55e-4*70000 + engine;
verifyEqual(testCase,mer.total_kg,expected,'RelTol',1e-12);
verifyEqual(testCase,mer.nozzle_kg,0);
verifyEqual(testCase,mer.source_variant,'mass_model_n_2.m');
end

function testFirstStage2014TwoStageExceptions(testCase)
stage.thrust_N = 200000;
stage.mixture_ratio_OF = 3.8;
stage.nozzle_area_ratio = 30;
masses.mp_kg = 9500;
masses.payload_above_kg = 3600;
masses.section_initial_mass_kg = 16000;
mer = thesis_legacy_mer(stage,masses,2,1);
ox = 9500*3.8/4.8;
fuel = 9500/4.8;
tank = 3*(.0107*ox+.128*fuel);
engine = 7.81e-4*200000 + 3.37e-5*200000*sqrt(30)+59;
expected = tank + 10*16000^.361 + 1.55e-4*200000 + engine;
verifyEqual(testCase,mer.total_kg,expected,'RelTol',1e-12);
end

function testFourStageIncludesNozzleAndFullEngine(testCase)
stage.thrust_N = 200000;
stage.mixture_ratio_OF = 3.8;
% Leave nozzle ratio unspecified: 4-stage lower stage default is 20.
masses.mp_kg = 9500;
masses.payload_above_kg = 3600;
masses.section_initial_mass_kg = 16000;
mer = thesis_legacy_mer(stage,masses,4,1);
expected_nozzle = 125*(9500/5400)^(2/3)*(20/10)^(1/4);
verifyEqual(testCase,mer.nozzle_area_ratio,20);
verifyEqual(testCase,mer.nozzle_kg,expected_nozzle,'RelTol',1e-12);
verifyEqual(testCase,mer.engine_kg, ...
    7.81e-4*200000+3.37e-5*200000*sqrt(20)+59,'RelTol',1e-12);
end

function testLegacyMERConvergesForTwoStages(testCase)
stage1 = struct('name','Stage 1','Isp_s',300, ...
    'delta_v_fraction',0.5,'epsilon0',0.15,'thrust_N',200000, ...
    'mixture_ratio_OF',3.8,'nozzle_area_ratio',30);
stage2 = struct('name','Stage 2','Isp_s',300, ...
    'delta_v_fraction',0.5,'epsilon0',0.10,'thrust_N',70000, ...
    'mixture_ratio_OF',3.8,'nozzle_area_ratio',20);
cfg.stages = [stage1 stage2];
opts.structural_model = 'legacy_mer';
out = thesis_mass_model(cfg,1000,6000,opts);
verifyEqual(testCase,out.structural_model,'legacy_mer');
verifyLessThanOrEqual(testCase,max([out.stages.mer_relative_residual]),0.001);
verifyGreaterThan(testCase,min([out.stages.epsilon]),0.05);
verifyLessThan(testCase,max([out.stages.epsilon]),0.17);
verifyEqual(testCase,out.stages(1).payload_above_kg, ...
    out.stages(2).section_initial_mass_kg,'RelTol',1e-12);
verifyEqual(testCase,out.GLOW_kg, ...
    1000+sum([out.stages.ms_kg])+sum([out.stages.mp_kg]), ...
    'RelTol',1e-12);
verifyEqual(testCase,out.stages(2).burn_time_s, ...
    out.stages(2).mp_kg*9.81*300/70000,'RelTol',1e-12);
end

function testSolidPropellantDoesNotSilentlyUseLiquidTanks(testCase)
stage.thrust_N = 70000;
stage.mixture_ratio_OF = 3.8;
stage.propellant_kind = 'solid';
masses.mp_kg = 2000;
masses.payload_above_kg = 1000;
masses.section_initial_mass_kg = 3500;
verifyError(testCase,@() thesis_legacy_mer(stage,masses,2,2), ...
    'thesis_legacy_mer:UnsupportedSolidPropellant');
end

function testKnownThreeStageAvionicsErrorIsVisible(testCase)
stage.thrust_N = 200000;
stage.mixture_ratio_OF = 3.8;
masses.mp_kg = 2000;
masses.payload_above_kg = 8000;
masses.section_initial_mass_kg = 10000;
masses.upper_next_kg = 3000;
opts.n3_first_stage_avionics = 'verbatim';
verifyError(testCase,@() thesis_legacy_mer(stage,masses,3,1,opts), ...
    'thesis_legacy_mer:InvalidAvionicsMass');
opts.n3_first_stage_avionics = 'corrected';
mer = thesis_legacy_mer(stage,masses,3,1,opts);
verifyEqual(testCase,mer.avionics_reference_mass_kg,2000);
end
