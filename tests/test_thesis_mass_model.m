function tests = test_thesis_mass_model
tests = functiontests(localfunctions);
end

function setupOnce(~)
addpath('configs');
addpath('util');
end

function testStageMassReproducesTsiolkovsky(testCase)
g0 = 9.80665;
payload = 1500;
dv = 2500;
Isp = 300;
epsilon = 0.10;

[ms, mp, k] = thesis_stage_mass(payload, dv, Isp, epsilon, g0);

m_initial = payload + ms + mp;
m_final = payload + ms;
dv_recovered = g0 * Isp * log(m_initial / m_final);

verifyEqual(testCase, dv_recovered, dv, 'RelTol', 1e-12);
verifyEqual(testCase, ms/(ms+mp), epsilon, 'RelTol', 1e-12);
verifyEqual(testCase, k, exp(dv/(g0*Isp)), 'RelTol', 1e-12);
end

function testMassModelDesignsFromUpperStageDown(testCase)
cfg.stages(1) = struct('name','Stage 1','Isp_s',280, ...
    'delta_v_fraction',0.45,'epsilon0',0.08);
cfg.stages(2) = struct('name','Stage 2','Isp_s',330, ...
    'delta_v_fraction',0.55,'epsilon0',0.10);

payload = 1000;
result = thesis_mass_model(cfg, payload, 9000);

verifyEqual(testCase, result.stages(2).payload_above_kg, payload, ...
    'RelTol', 1e-12);
expected_stage1_payload = payload + result.stages(2).ms_kg + ...
    result.stages(2).mp_kg;
verifyEqual(testCase, result.stages(1).payload_above_kg, ...
    expected_stage1_payload, 'RelTol', 1e-12);
verifyEqual(testCase, result.GLOW_kg, ...
    payload + sum([result.stages.ms_kg]) + sum([result.stages.mp_kg]), ...
    'RelTol', 1e-12);
verifyEqual(testCase, sum(result.delta_v_fractions), 1, 'AbsTol', 1e-12);
end

function testInfeasibleStageRejected(testCase)
% Large Delta-V with a high structural factor makes epsilon*k >= 1.
verifyError(testCase, @() thesis_stage_mass(1000, 10000, 250, 0.30), ...
    'thesis_stage_mass:InfeasibleStage');
end

function testHistoricalStructuralFactorTable(testCase)
db = thesis_structural_factor_database();
verifyEqual(testCase, db.small.stage1, [0.057 0.073 0.085], ...
    'AbsTol', 1e-12);
verifyEqual(testCase, db.heavy.booster, [0.080 0.117 0.149], ...
    'AbsTol', 1e-12);
end

function testHistoricalPropellantTable(testCase)
prop = thesis_propellant_database();
idx = find(strcmp({prop.name}, 'LOX/H2'), 1);
verifyNotEmpty(testCase, idx);
verifyEqual(testCase, prop(idx).Isp_s, 462);
verifyEqual(testCase, prop(idx).mixture_ratio_OF, 3.8, 'AbsTol', 1e-12);
verifyEqual(testCase, prop(idx).rho_oxidizer_kg_m3, 1142);
verifyEqual(testCase, prop(idx).rho_fuel_kg_m3, 71);
end

function testDocumentedMEREquations(testCase)
stage.thrust_N = 1.0e6;
stage.nozzle_area_ratio = 25;
masses.mp_kg = 10000;
masses.m0_kg = 15000;
propellant.mixture_ratio_OF = 2.5;

mer = thesis_mer_components(stage, masses, propellant);

verifyEqual(testCase, mer.thrust_structure_kg, 255, 'RelTol', 1e-12);
verifyEqual(testCase, mer.motor_casing_kg, 1350, 'RelTol', 1e-12);
verifyEqual(testCase, mer.engine_kg, ...
    7.81e-4*1.0e6 + 3.37e-5*1.0e6*sqrt(25) + 59, ...
    'RelTol', 1e-12);
verifyEqual(testCase, mer.oxidizer_kg + mer.fuel_kg, masses.mp_kg, ...
    'RelTol', 1e-12);
end
