function tests = test_feedback_and_ariane_reference
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'validation'));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
end

function testResidualDeltaVExcessIsNegativeCorrection(testCase)
stage=struct('Isp_s',320,'ms_kg',500,'mp_kg',1500);
out=thesis_propellant_residual_delta_v(stage,1000,300,9.80665);
expected=-320*9.80665*log((1000+500+300)/(1000+500));
verifyEqual(testCase,out.delta_v_correction_m_s,expected,'RelTol',1e-12);
verifyEqual(testCase,out.mode,'excess');
verifyFalse(testCase,out.approximation);
end

function testResidualDeltaVShortfallIsExplicitApproximation(testCase)
stage=struct('Isp_s',320,'ms_kg',500,'mp_kg',1500);
out=thesis_propellant_residual_delta_v(stage,1000,-100,9.80665);
verifyGreaterThan(testCase,out.delta_v_correction_m_s,0);
verifyEqual(testCase,out.mode,'shortfall');
verifyTrue(testCase,out.approximation);
end

function testArianeReferenceReproducesReportedReduction(testCase)
r=ariane5_2014_optimization_reference();
verifyEqual(testCase,r.mission.payload_kg,19300);
verifyEqual(testCase,r.optimum.number_of_boosters,2);
verifyEqual(testCase,r.optimum.delta_v_fractions,[.25 .49 .26], ...
    'AbsTol',1e-12);
verifyEqual(testCase,r.optimum.reported_mass_reduction_kg,84063.5, ...
    'AbsTol',1e-9);
verifyEqual(testCase, ...
    100*r.optimum.reported_mass_reduction_kg/r.original.reported_vehicle_mass_kg, ...
    11.001047,'AbsTol',1e-5);
verifyEqual(testCase,r.optimum.flight_time_s,462.8);
verifyEqual(testCase,r.optimum.gravity_turn_end_altitude_m,120.4e3);
end

function testArianeDesignSpacePreservesUnresolvedDeltaVPath(testCase)
s=ariane5_2014_reported_design_space();
verifyNumElements(testCase,s.core_diameter_m,11);
verifyNumElements(testCase,s.stage_thrust_scale,5);
verifyNumElements(testCase,s.booster_count,2);
verifyNumElements(testCase,s.booster_burn_fraction,5);
verifyNumElements(testCase,s.booster_diameter_m_reported_center,5);
verifyEmpty(testCase,s.delta_v_sequence);
verifyEqual(testCase,s.delta_v_reported_points,23);
verifyEqual(testCase,s.reported_total_simulations,170);
end

function testVegaReferenceKeepsChapter6ComparisonTargets(testCase)
r=vega_2014_reference();
verifyEqual(testCase,r.reported.table6_4_reference_glow_kg,132530);
verifyEqual(testCase,r.reported.table6_4_simulated_glow_kg,126085);
verifyEqual(testCase,r.reported.trajectory_validation_last_stage_unburned_percent,34);
verifyEqual(testCase,r.reported.coast_time_s,[3 3 3]);
end

function testProtonReferenceKeepsTextAndTableDiscrepancy(testCase)
r=proton_2014_reference();
verifyEqual(testCase,r.reported.GLOW_deviation_percent_text,6.2);
verifyEqual(testCase,r.reported.table6_6_deviation_percent,6.3);
verifyEqual(testCase,r.reported.trajectory_validation_last_stage_unburned_percent,38);
verifyEqual(testCase,r.reported.integrated_final_propellant_reserve_percent,5);
verifyEqual(testCase,r.reported.coast_time_s,[3 3]);
end
