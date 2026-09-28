function tests = test_three_phase_components
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'util'));
end

function testStagedTpbvpSingleSegmentMatchesAnalyticCase(testCase)
initial=struct('x_m',0,'y_m',0,'vx_m_s',0,'vy_m_s',0, ...
    'mass_kg',1000);
target=struct('y_m',0,'vx_m_s',100,'vy_m_s',0);
seg=struct('thrust_N',10000,'mdot_kg_s',0,'duration_s',20, ...
    'dry_mass_drop_after_kg',0);
opts=struct('g_m_s2',0,'tf_guess_s',10,'rel_tol',1e-8, ...
    'abs_tol',1e-10,'mesh_points',31,'output_points',101);

r=thesis_staged_free_flight_tpbvp(initial,target,seg,opts);
verifyTrue(testCase,r.converged);
verifyEqual(testCase,r.tf_s,10,'AbsTol',1e-5);
verifyEqual(testCase,r.x_m(end),500,'AbsTol',1e-3);
verifyEqual(testCase,r.vx_m_s(end),100,'AbsTol',1e-6);
verifyEqual(testCase,r.final_hamiltonian,-1,'AbsTol',1e-6);
end

function testStagedTpbvpCanCrossSerialBoundary(testCase)
initial=struct('x_m',0,'y_m',0,'vx_m_s',0,'vy_m_s',0, ...
    'mass_kg',1000);
target=struct('y_m',0,'vx_m_s',150,'vy_m_s',0);
template=struct('thrust_N',10000,'mdot_kg_s',0, ...
    'duration_s',10,'dry_mass_drop_after_kg',0);
schedule=repmat(template,1,2);
opts=struct('g_m_s2',0,'tf_guess_s',15,'rel_tol',1e-8, ...
    'abs_tol',1e-10,'mesh_points',41,'output_points',121);

r=thesis_staged_free_flight_tpbvp(initial,target,schedule,opts);
verifyTrue(testCase,r.converged);
verifyEqual(testCase,r.tf_s,15,'AbsTol',1e-5);
verifyEqual(testCase,r.vx_m_s(end),150,'AbsTol',1e-6);
verifyEqual(testCase,r.schedule_index(end),2);
end

function testAtmosphericPropagationStopsAtKnudsenFive(testCase)
cfg.name='KNUDSEN-TEST';
st=struct('name','Test stage','Isp_s',1000,'thrust_N',2e6, ...
    'mp_kg',20000,'ms_kg',1000,'fs_struct',1000/21000, ...
    'CdA_m2',0.1,'reference_area_m2',0.2,'diameter_m',0.4, ...
    'drag_model','thesis_mach_polynomial');
cfg.stages=st;
cfg.knudsen_characteristic_length_m=0.05;
cfg.knudsen_transition_threshold=5;

mission=struct('target_alt',200e3,'launch_lat',0);
guidance=struct('t_pitch',5,'pitch_kick',deg2rad(3),'kick_dur',1);
phase=propagate_to_knudsen_transition(cfg,mission,guidance,100);

verifyTrue(testCase,phase.transition.detected);
verifyGreaterThanOrEqual(testCase,phase.transition.knudsen,5-1e-4);
verifyLessThan(testCase,phase.transition.remaining_propellant_kg,st.mp_kg);
verifyGreaterThan(testCase,phase.transition.remaining_propellant_kg,0);
verifyEqual(testCase,phase.transition.stage_index,1);
verifyEqual(testCase,phase.t(end),phase.transition.time_s,'RelTol',1e-8);
end

function testRemainingScheduleStartsWithUnburnedPropellant(testCase)
traj_cfg.name='TEST';
s1=struct('name','A','Isp_s',300,'thrust_N',100e3, ...
    'mp_kg',1000,'ms_kg',100,'fs_struct',100/1100,'CdA_m2',1);
s2=struct('name','B','Isp_s',350,'thrust_N',50e3, ...
    'mp_kg',400,'ms_kg',50,'fs_struct',50/450,'CdA_m2',0.5);
traj_cfg.stages=[s1 s2];
phase.transition=struct('detected',true,'stage_index',1, ...
    'remaining_propellant_kg',250);
schedule=remaining_propulsion_schedule(traj_cfg,phase);

verifyEqual(testCase,numel(schedule),2);
verifyEqual(testCase,schedule(1).propellant_kg,250);
verifyEqual(testCase,schedule(2).propellant_kg,400);
verifyEqual(testCase,schedule(1).dry_mass_drop_after_kg,100);
verifyEqual(testCase,schedule(2).dry_mass_drop_after_kg,0);
end
