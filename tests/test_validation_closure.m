function tests = test_validation_closure
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'validation'));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
end

function testHistoricalDeviationMetric(testCase)
r=historical_percent_deviation([100 200],[90 250]);
verifyEqual(testCase,r,[10 25],'AbsTol',1e-12);
verifyTrue(testCase,isnan(historical_percent_deviation(0,1)));
end

function testChapter6TablesCloseWithinPrintedRounding(testCase)
r=run_validation_closure(struct( ...
    'run_full_trajectory',false,'run_ariane_trajectory',false));

verifyEqual(testCase,r.vega.mass_table.status,'verified');
verifyLessThan(testCase,r.vega.mass_table.max_rounding_error_percent,0.12);
verifyLessThan(testCase,r.vega.geometry_table.max_rounding_error_percent,0.12);

verifyEqual(testCase,r.proton.mass_table.status,'verified');
verifyLessThan(testCase,r.proton.mass_table.max_rounding_error_percent,0.12);
verifyLessThan(testCase,r.proton.geometry_table.max_rounding_error_percent,0.12);

verifyEqual(testCase,r.ariane5.mass_table.status,'verified');
verifyLessThan(testCase,r.ariane5.mass_table.max_rounding_error_percent,0.12);
verifyLessThan(testCase,r.ariane5.geometry_table.max_rounding_error_percent,0.12);
end

function testVegaClosurePreservesKnDiscrepancy(testCase)
r=run_validation_closure(struct( ...
    'run_full_trajectory',false,'run_ariane_trajectory',false));
verifyTrue(testCase,r.vega.trajectory.thesis_fixture.kn_detected);
verifyGreaterThan(testCase,r.vega.trajectory.thesis_fixture.kn_time_s, ...
    r.vega.reference.reported.gravity_turn_end_time_s);
verifyGreaterThan(testCase,r.vega.trajectory.thesis_fixture.max_q_altitude_m,7e3);
verifyLessThan(testCase,r.vega.trajectory.thesis_fixture.max_q_altitude_m,12e3);
verifyEqual(testCase,r.vega.closure_status,'closed_provenance_gap');
end

function testProtonClosureMakesLiteralLiftOffContradictionExplicit(testCase)
r=run_validation_closure(struct( ...
    'run_full_trajectory',false,'run_ariane_trajectory',false));
verifyLessThan(testCase,r.proton.trajectory.thesis_semantic.liftoff_TW,1);
verifyFalse(testCase,r.proton.trajectory.thesis_semantic.kn_detected);
verifyGreaterThan(testCase, ...
    r.proton.trajectory.recovered_development.liftoff_TW,1);
verifyTrue(testCase, ...
    r.proton.trajectory.recovered_development.kn_detected);
verifyEqual(testCase,r.proton.closure_status,'closed_provenance_gap');
end

function testArianeClosureDoesNotInventMissingSearchPath(testCase)
r=run_validation_closure(struct( ...
    'run_full_trajectory',false,'run_ariane_trajectory',false));
verifyEqual(testCase,r.ariane5.design_space.reported_total_simulations,170);
verifyEqual(testCase,r.ariane5.design_space.delta_v_reported_points,23);
verifyFalse(testCase,r.ariane5.design_space.exact_delta_v_sequence_available);
verifyEqual(testCase,r.ariane5.design_space.status,'provenance_gap');
verifyTrue(testCase,r.validation_closure_complete);
end

function testFullClosureDiagnostic(testCase)
opts=struct('run_full_trajectory',true, ...
    'run_ariane_trajectory',true,'print_summary',true);
r=run_validation_closure(opts);
verifyTrue(testCase,r.validation_closure_complete);
verifyTrue(testCase,r.vega.trajectory.full.transition_detected);
verifyTrue(testCase,isfield(r.proton.trajectory.full,'status'));
verifyTrue(testCase,isfield(r.ariane5.trajectory,'status'));
% Historical discrepancies are findings, not CI failures.
verifyEqual(testCase,r.overall_status,'closed_with_documented_provenance_gaps');
end
