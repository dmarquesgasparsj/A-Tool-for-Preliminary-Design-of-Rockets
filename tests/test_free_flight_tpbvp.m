function tests = test_free_flight_tpbvp
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'util'));
end

function testZeroGravityHorizontalMinimumTime(testCase)
% Analytic reference: constant acceleration a=10 m/s^2 from 0 to 100 m/s.
% Minimum-time steering is horizontal and tf=10 s.
initial=struct('x_m',0,'y_m',0,'vx_m_s',0,'vy_m_s',0, ...
    'mass_kg',1000);
target=struct('y_m',0,'vx_m_s',100,'vy_m_s',0);
propulsion=struct('thrust_N',10000,'mdot_kg_s',0);
opts=struct('g_m_s2',0,'tf_guess_s',10,'rel_tol',1e-8, ...
    'abs_tol',1e-10,'mesh_points',31,'output_points',101);

r=thesis_free_flight_tpbvp(initial,target,propulsion,opts);

verifyTrue(testCase,r.converged);
verifyEqual(testCase,r.tf_s,10,'AbsTol',1e-5);
verifyEqual(testCase,r.vx_m_s(end),100,'AbsTol',1e-6);
verifyEqual(testCase,r.vy_m_s(end),0,'AbsTol',1e-8);
verifyEqual(testCase,r.y_m(end),0,'AbsTol',1e-8);
verifyEqual(testCase,r.x_m(end),500,'AbsTol',1e-3);
verifyEqual(testCase,r.final_hamiltonian,-1,'AbsTol',1e-6);
verifyLessThan(testCase,max(abs(r.steering_angle_rad)),1e-5);
end

function testPositiveMassFlowRespectsPropellantBound(testCase)
initial=struct('x_m',0,'y_m',100e3,'vx_m_s',2000,'vy_m_s',100, ...
    'mass_kg',5000);
target=struct('y_m',100e3,'vx_m_s',2100,'vy_m_s',0);
propulsion=struct('thrust_N',100e3,'mdot_kg_s',10, ...
    'propellant_available_kg',1000);
opts=struct('g_m_s2',0,'tf_guess_s',5,'rel_tol',1e-5, ...
    'abs_tol',1e-7,'mesh_points',31,'output_points',51);

r=thesis_free_flight_tpbvp(initial,target,propulsion,opts);
verifyLessThan(testCase,r.tf_s,100);
verifyLessThan(testCase,r.propellant_used_kg,1000);
verifyGreaterThan(testCase,min(r.mass_kg),0);
verifyEqual(testCase,r.vx_m_s(end),target.vx_m_s,'AbsTol',1e-3);
end

function testMassFlowNeedsAvailablePropellant(testCase)
initial=struct('x_m',0,'y_m',0,'vx_m_s',0,'vy_m_s',0, ...
    'mass_kg',1000);
target=struct('y_m',0,'vx_m_s',100);
propulsion=struct('thrust_N',10000,'mdot_kg_s',1);
verifyError(testCase, ...
    @()thesis_free_flight_tpbvp(initial,target,propulsion, ...
    struct('g_m_s2',0,'tf_guess_s',10)), ...
    'thesis_free_flight_tpbvp:MissingPropellantAvailable');
end
