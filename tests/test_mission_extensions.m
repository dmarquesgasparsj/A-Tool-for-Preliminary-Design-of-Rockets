function tests = test_mission_extensions
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'validation'));
end

function testHistoricalLaunchInitialConditionsStayDefault(testCase)
m=struct('launch_lat',0);
init=launch_initial_conditions(m,1000);
env=earth_constants();
verifyEqual(testCase,init.radius_m,env.Re,'AbsTol',1e-9);
verifyEqual(testCase,init.radial_speed_m_s,0,'AbsTol',1e-12);
verifyEqual(testCase,init.inertial_tangential_speed_m_s, ...
    env.omega*env.Re,'RelTol',1e-12);
verifyEqual(testCase,init.flight_path_angle_deg,90,'AbsTol',1e-12);
verifyTrue(testCase,init.is_historical_ground_default);
end

function testAirLaunchInitialState(testCase)
m=struct('launch_lat',deg2rad(30),'initial_altitude_m',12000, ...
    'initial_speed_m_s',250,'initial_flight_path_angle_deg',10, ...
    'include_earth_rotation',false);
init=launch_initial_conditions(m,5000);
verifyEqual(testCase,init.altitude_m,12000);
verifyEqual(testCase,init.radial_speed_m_s,250*sin(deg2rad(10)), ...
    'RelTol',1e-12);
verifyEqual(testCase,init.inertial_tangential_speed_m_s, ...
    250*cos(deg2rad(10)),'RelTol',1e-12);
verifyEqual(testCase,init.mode,'air_or_moving_launch');
end

function testInclinedGuidanceStartsAtRequestedGamma(testCase)
m=struct('launch_lat',0,'initial_flight_path_angle_deg',30);
init=launch_initial_conditions(m,1000);
[u,meta]=launch_guidance(m,struct('initial_angle_hold_s',5),init);
state=init.state;
dir=u(0,state);
verifyEqual(testCase,dir,[sin(deg2rad(30));cos(deg2rad(30))], ...
    'AbsTol',1e-12);
verifyEqual(testCase,meta.profile,'initial-angle-then-gravity-turn');
end

function testThrustMisalignmentRotation(testCase)
u=apply_thrust_misalignment([1;0],deg2rad(5));
verifyEqual(testCase,u,[cos(deg2rad(5));sin(deg2rad(5))], ...
    'AbsTol',1e-12);
u3=apply_thrust_misalignment([1;0;0],pi/2,[0;0;1]);
verifyEqual(testCase,u3,[0;1;0],'AbsTol',1e-12);
end

function testMisalignmentChangesAscentAcceleration(testCase)
env=earth_constants();
stage=struct('thrust_N',100e3,'Isp_s',300,'CdA_m2',0, ...
    'thrust_misalignment_rad',0);
state=[env.Re;0;0;0;1000];
guide=@(~,~)[1;0];
a0=equations_of_motion(0,state,env,stage,guide);
stage.thrust_misalignment_rad=deg2rad(5);
a1=equations_of_motion(0,state,env,stage,guide);
verifyLessThan(testCase,a1(3),a0(3));
verifyGreaterThan(testCase,a1(4),a0(4));
end

function testCentralGravityAndJ2(testCase)
env=earth_constants();
r=[env.Re+500e3;0;0];
a0=earth_gravity_acceleration(r,struct('include_J2',false));
verifyEqual(testCase,a0,[-env.mu/r(1)^2;0;0],'RelTol',1e-12);
aj=earth_gravity_acceleration(r,struct('include_J2',true));
verifyNotEqual(testCase,aj(1),a0(1));
verifyEqual(testCase,aj(2:3),[0;0],'AbsTol',1e-12);
end

function testLongCoastCentralEnergyConservation(testCase)
env=earth_constants();
r0=env.Re+500e3;
v0=sqrt(env.mu/r0);
init=struct('r_eci_m',[r0;0;0],'v_eci_m_s',[0;v0;0]);
period=2*pi*sqrt(r0^3/env.mu);
p=propagate_orbit_3d(init,period,struct('include_J2',false, ...
    'output_points',201));
rel=(max(p.specific_energy_J_kg)-min(p.specific_energy_J_kg))/ ...
    abs(mean(p.specific_energy_J_kg));
verifyLessThan(testCase,rel,1e-7);
verifyLessThan(testCase,norm(p.r_eci_m(end,:)'-init.r_eci_m)/r0,2e-5);
end

function testJ2ChangesInclinedLongCoast(testCase)
env=earth_constants();
r0=env.Re+700e3;
v0=sqrt(env.mu/r0);
inc=deg2rad(63.4);
init=struct('r_eci_m',[r0;0;0], ...
    'v_eci_m_s',[0;v0*cos(inc);v0*sin(inc)]);
a=propagate_orbit_3d(init,86400,struct('include_J2',false, ...
    'output_points',101));
b=propagate_orbit_3d(init,86400,struct('include_J2',true, ...
    'output_points',101));
verifyGreaterThan(testCase,norm(a.r_eci_m(end,:)-b.r_eci_m(end,:)),100);
end

function testLeoToGeoHohmannReferenceRange(testCase)
g=geo_transfer_analysis(200e3);
verifyGreaterThan(testCase,g.delta_v_departure_m_s,2400);
verifyLessThan(testCase,g.delta_v_departure_m_s,2500);
verifyGreaterThan(testCase,g.delta_v_apogee_m_s,1400);
verifyLessThan(testCase,g.delta_v_apogee_m_s,1550);
verifyGreaterThan(testCase,g.transfer_time_h,5);
verifyLessThan(testCase,g.transfer_time_h,6);
verifyGreaterThan(testCase,g.geo_altitude_m/1000,35700);
verifyLessThan(testCase,g.geo_altitude_m/1000,35900);
end

function testGeoPlaneChangeCostsMore(testCase)
a=geo_transfer_analysis(200e3,struct('initial_inclination_deg',0));
b=geo_transfer_analysis(200e3,struct('initial_inclination_deg',28.5));
verifyGreaterThan(testCase,b.total_delta_v_m_s,a.total_delta_v_m_s);
end

function testEarthMarsHohmannPatchedConicRange(testCase)
m=interplanetary_transfer_analysis(1.523679,200e3);
verifyGreaterThan(testCase,m.departure_v_inf_m_s,2800);
verifyLessThan(testCase,m.departure_v_inf_m_s,3100);
verifyGreaterThan(testCase,m.C3_km2_s2,8);
verifyLessThan(testCase,m.C3_km2_s2,10);
verifyGreaterThan(testCase,m.earth_injection_delta_v_m_s,3500);
verifyLessThan(testCase,m.earth_injection_delta_v_m_s,3700);
verifyGreaterThan(testCase,m.transfer_time_days,250);
verifyLessThan(testCase,m.transfer_time_days,270);
end

function testNormalizedCostModelIsTransparentAndMonotonic(testCase)
d1.GLOW_kg=10000;
d1.stages=struct('name','S','ms_kg',1000);
d2=d1;
d2.GLOW_kg=20000;
d2.stages.ms_kg=2000;
cfg=cost_model_template();
c1=estimate_launcher_cost(d1,cfg);
c2=estimate_launcher_cost(d2,cfg);
verifyEqual(testCase,c1.currency,'cost_index');
verifyGreaterThan(testCase,c2.total_program_cost,c1.total_program_cost);
verifyGreaterThan(testCase,c1.development_cost,0);
verifyGreaterThan(testCase,c1.production_cost,0);
end

function testLearningCurveReducesLaterUnitCost(testCase)
d.GLOW_kg=10000;
d.stages=struct('name','S','ms_kg',1000);
cfg=cost_model_template();
cfg.program.units=4;
c=estimate_launcher_cost(d,cfg);
b=c.learning_curve_exponent;
first=c.components(1).first_unit_cost;
fourth=first*4^b;
verifyLessThan(testCase,fourth,first);
end

function testConfigPreservesMisalignmentAndCostDrivers(testCase)
mission=struct('payload_kg',10,'delta_v_budget_m_s',1000);
s=struct('name','S','propellant_name','HTPB/AP', ...
    'delta_v_fraction',1,'thrust_N',100e3,'nozzle_area_ratio',10, ...
    'thrust_misalignment_rad',0.01,'cost_complexity_factor',1.3, ...
    'quantity',2);
cfg=make_launcher_config(mission,s);
verifyEqual(testCase,cfg.stages.thrust_misalignment_rad,0.01);
verifyEqual(testCase,cfg.stages.cost_complexity_factor,1.3);
verifyEqual(testCase,cfg.stages.quantity,2);
end


function testAtmosphereRelativeSpeedRemovesEarthRotation(testCase)
env=earth_constants();
env.launch_lat=0;
env.atmosphere_rotates=true;
r=env.Re+12000;
vrotation=env.omega*r;
air=atmosphere_relative_velocity_2d(r,0,vrotation+250,env);
verifyEqual(testCase,air.speed_m_s,250,'RelTol',1e-12);
verifyEqual(testCase,air.atmosphere_tangential_speed_m_s,vrotation, ...
    'RelTol',1e-12);
end

function testInclinedGroundLaunchGetsAutomaticSteeringHold(testCase)
m=struct('launch_lat',0,'initial_flight_path_angle_deg',30, ...
    'include_earth_rotation',true);
init=launch_initial_conditions(m,1000);
[u,meta]=launch_guidance(m,struct(),init);
verifyEqual(testCase,meta.hold_duration_s,1,'AbsTol',1e-12);
verifyEqual(testCase,u(0,init.state), ...
    [sin(deg2rad(30));cos(deg2rad(30))],'AbsTol',1e-12);
end

function testInterplanetaryTargetSpeedOverride(testCase)
base=interplanetary_transfer_analysis(1.523679,200e3);
custom=interplanetary_transfer_analysis(1.523679,200e3, ...
    struct('target_body_circular_speed_m_s', ...
    base.target_circular_speed_m_s+1000));
verifyEqual(testCase,custom.target_circular_speed_m_s, ...
    base.target_circular_speed_m_s+1000,'AbsTol',1e-12);
verifyNotEqual(testCase,custom.arrival_v_inf_m_s,base.arrival_v_inf_m_s);
end

function testKnudsenTransitionCanOccurAtLaunch(testCase)
base=general_launcher_preset('illustrative_two_stage');
mass=thesis_iterative_mass_model(base);
cfg=trajectory_config_from_mass_result(base,mass);
mission=struct('target_alt',300e3,'launch_lat',0, ...
    'initial_altitude_m',200e3,'initial_speed_m_s',1000, ...
    'initial_flight_path_angle_deg',0);
traj_params=struct('initial_angle_hold_s',0);
p=propagate_to_knudsen_transition(cfg,mission,traj_params, ...
    base.mission.payload_kg);
verifyTrue(testCase,p.transition.detected);
verifyEqual(testCase,p.transition.time_s,0,'AbsTol',0);
verifyEqual(testCase,p.transition.burned_propellant_kg,0,'AbsTol',0);
verifyEqual(testCase,p.transition.remaining_propellant_kg, ...
    cfg.stages(1).mp_kg,'RelTol',1e-12);
end


function testAirLaunchGravityTurnAlignsWithAirRelativeVelocity(testCase)
m=struct('launch_lat',0,'initial_altitude_m',12000, ...
    'initial_speed_m_s',250,'initial_flight_path_angle_deg',10, ...
    'include_earth_rotation',true);
init=launch_initial_conditions(m,1000);
[u,~]=launch_guidance(m,struct('initial_angle_hold_s',0),init);
dir=u(0,init.state);
expected=[sin(deg2rad(10));cos(deg2rad(10))];
verifyEqual(testCase,dir,expected,'AbsTol',1e-12);
end


function testMisalignmentSurvivesMassToTrajectoryAdapter(testCase)
mission=struct('payload_kg',100,'delta_v_budget_m_s',1500, ...
    'orbit_altitude_km',100);
s=struct('name','S','propellant_name','HTPB/AP', ...
    'delta_v_fraction',1,'thrust_N',150e3,'nozzle_area_ratio',12, ...
    'diameter_m',2,'thrust_misalignment_rad',0.02);
cfg=make_launcher_config(mission,s);
mass=thesis_iterative_mass_model(cfg);
tcfg=trajectory_config_from_mass_result(cfg,mass);
verifyEqual(testCase,tcfg.stages.thrust_misalignment_rad,0.02, ...
    'AbsTol',1e-12);
end
