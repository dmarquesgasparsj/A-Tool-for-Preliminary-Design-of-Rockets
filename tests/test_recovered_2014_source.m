function tests = test_recovered_2014_source
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'validation'));
end

function testRecoveredVegaInputs(testCase)
cfg = vega_2014_legacy_inputs();
verifyEqual(testCase, cfg.payload_kg, 1500);
verifyEqual(testCase, cfg.delta_v_estimation_m_s, 9200);
verifyEqual(testCase, cfg.Isp_s, [280 289 294 317]);
verifyEqual(testCase, cfg.thrust_N, [2092e3 959e3 230e3 2.2e3]);
verifyEqual(testCase, cfg.delta_v_fraction, [0.20 0.25 0.40 0.15], ...
    'AbsTol', 1e-12);
verifyEqual(testCase, cfg.nozzle_area_ratio, [20 30 60 100]);
end

function testLegacyMERAggregation(testCase)
mp = 5400;
mref = 10000;
T = 1e6;
OF = 3;
E = 10;
mer = thesis_legacy_akin_mass(mp,mref,T,OF,E);

fuel = mp/(OF+1);
oxidizer = OF*mp/(OF+1);
expected = 0.128*fuel + 0.0107*oxidizer + ...
    10*mref^0.361 + 125 + ...
    (7.81e-4*T + 3.37e-5*T*sqrt(E) + 59) + ...
    2.55e-4*T;

verifyEqual(testCase, mer.total_kg, expected, 'RelTol', 1e-12);
verifyEqual(testCase, mer.fuel_kg + mer.oxidizer_kg, mp, 'RelTol', 1e-12);
end

function testLegacyEpsilonGrid(testCase)
scan = thesis_legacy_epsilon_scan(1500, 1500, 317, 2.2e3, 4, 100);
verifyEqual(testCase, scan.epsilon_grid, 0.05:0.01:0.17, 'AbsTol', 1e-12);
verifyEqual(testCase, numel(scan.candidates), 13);

ratios = [scan.candidates.ratio_mer_to_tsiolkovsky];
verifyTrue(testCase, all(isfinite(ratios)));
verifyTrue(testCase, all(ratios > 0));
end

function testLegacySelectionIsLastAcceptedCandidate(testCase)
scan = thesis_legacy_epsilon_scan(1500, 1500, 317, 2.2e3, 4, 100);
if scan.has_match
    verifyEqual(testCase, scan.legacy_selected.epsilon, ...
        scan.accepted(end).epsilon, 'AbsTol', 1e-12);
end
end
