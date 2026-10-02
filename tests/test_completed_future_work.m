function tests = test_completed_future_work
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
end

function testEngineMassHistoricalMode(testCase)
s=struct('thrust_N',1e6,'nozzle_area_ratio',25);
r=estimate_engine_mass(s,struct('mode','thesis_2014'));
expected=7.81e-4*1e6+3.37e-5*1e6*sqrt(25)+59;
verifyEqual(testCase,r.mass_kg,expected,'RelTol',1e-12);
verifyFalse(testCase,r.calibrated);
end

function testEngineMassCalibratedPowerLaw(testCase)
s=struct('thrust_N',2e6,'nozzle_area_ratio',40, ...
    'chamber_pressure_Pa',10e6,'mixture_ratio_OF',2.5);
m=struct('mode','reference_powerlaw','reference_mass_kg',1000, ...
    'reference_thrust_N',1e6,'reference_chamber_pressure_Pa',5e6, ...
    'reference_area_ratio',20,'reference_mixture_ratio_OF',2.5, ...
    'exponents',[0.5 0.2 0.1 0]);
r=estimate_engine_mass(s,m);
expected=1000*2^0.5*2^0.2*2^0.1;
verifyEqual(testCase,r.mass_kg,expected,'RelTol',1e-12);
verifyTrue(testCase,r.calibrated);
end

function testModernMERUsesConfiguredEngineModel(testCase)
s=struct('name','L','propellant_name','LOX/RP1', ...
    'propulsion_type','liquid','Isp_s',300,'thrust_N',2e6, ...
    'nozzle_area_ratio',40,'mixture_ratio_OF',2.27, ...
    'engine_mass_model',struct('mode','reference_powerlaw', ...
        'reference_mass_kg',900,'reference_thrust_N',1e6, ...
        'reference_chamber_pressure_Pa',5e6,'reference_area_ratio',20, ...
        'reference_mixture_ratio_OF',2.27,'exponents',[0.5 0.2 0.1 0]), ...
    'pressure_nozzle',struct('chamber_pressure_Pa',10e6));
m=modern_stage_mer(s,1000,10000);
verifyTrue(testCase,isfield(m,'engine_mass_detail'));
verifyEqual(testCase,m.engine_kg,m.engine_mass_detail.mass_kg,'RelTol',1e-12);
end

function testShapeSpecificDragBlendsAndDiffersByGeometry(testCase)
M=[0.8 5];
[c1,d1]=nose_cone_drag_coefficient(M,'ogive',4,1);
[c2,~]=nose_cone_drag_coefficient(M,'ellipse',4,1);
verifyEqual(testCase,c1(1),thesis_cd_mach(M(1)),'RelTol',1e-12);
verifyGreaterThan(testCase,c1(2),0);
verifyGreaterThan(testCase,c2(2),0);
verifyGreaterThan(testCase,abs(c1(2)-c2(2)),1e-5);
verifyEqual(testCase,d1.blend_weight(2),1,'AbsTol',1e-12);
end

function testAerodynamicDragUsesShapeModel(testCase)
stage=struct('drag_model','shape_specific','diameter_m',2, ...
    'nose_cone',struct('shape','haack','length_m',4,'radius_m',1));
a=aerodynamic_drag(stage,30000,1500);
verifyGreaterThan(testCase,a.drag_N,0);
verifyGreaterThan(testCase,a.Cd,0);
verifyTrue(testCase,isfield(a,'shape_detail'));
verifyEqual(testCase,a.reference_area_m2,pi,'RelTol',1e-12);
end

function testSolidGrainGeometriesProduceBallistics(testCase)
a=0.005/(1e6^0.30);
prop=struct('density_kg_m3',1700,'burn_rate_a_m_s_Pa_n',a, ...
    'burn_rate_n',0.30,'throat_area_m2',0.01,'cstar_m_s',1500, ...
    'gamma',1.2,'nozzle_area_ratio',12);
base=struct('outer_radius_m',0.30,'inner_radius_m',0.08, ...
    'segment_length_m',0.40,'segments',3);
base.geometry='bates';
b=solid_grain_ballistics(base,prop,struct('samples',101));
verifyGreaterThan(testCase,b.initial_propellant_kg,0);
verifyGreaterThan(testCase,b.burn_time_s,0);
verifyGreaterThan(testCase,b.peak_chamber_pressure_Pa,0);
verifyGreaterThan(testCase,b.mean_thrust_N,0);
verifyLessThan(testCase,b.propellant_remaining_kg(end), ...
    b.propellant_remaining_kg(1));

base.geometry='inhibited_core';
c=solid_grain_ballistics(base,prop,struct('samples',101));
verifyGreaterThan(testCase,abs(b.burning_area_m2(end)- ...
    c.burning_area_m2(end)),1e-3);
end

function testThirdBodyDifferentialAcceleration(testCase)
r=[7000e3;0;0];
rb=[149597870700;0;0];
a=third_body_acceleration(r,rb,1.32712440041279419e20);
verifySize(testCase,a,[3 1]);
verifyTrue(testCase,all(isfinite(a)));
verifyGreaterThan(testCase,a(1),0);
end

function testSunMoonPropagationChangesLongCoast(testCase)
env=earth_constants();
r0=env.Re+1000e3;
v0=sqrt(env.mu/r0);
init=struct('r_eci_m',[r0;0;0],'v_eci_m_s',[0;v0;0]);
a=propagate_orbit_3d(init,12*3600,struct('output_points',51));
b=propagate_orbit_3d(init,12*3600,struct('output_points',51, ...
    'include_sun',true,'include_moon',true));
verifyGreaterThan(testCase,norm(a.r_eci_m(end,:)-b.r_eci_m(end,:)),0.01);
verifyTrue(testCase,b.include_sun);
verifyTrue(testCase,b.include_moon);
end

function testMisalignmentMonteCarloIsReproducible(testCase)
z=thrust_misalignment_monte_carlo(0,100);
verifyEqual(testCase,z.mean_delta_v_loss_fraction,0,'AbsTol',0);
a=thrust_misalignment_monte_carlo(deg2rad(0.5),1000,struct('seed',7));
b=thrust_misalignment_monte_carlo(deg2rad(0.5),1000,struct('seed',7));
verifyEqual(testCase,a.angle_rad,b.angle_rad,'AbsTol',0);
verifyGreaterThan(testCase,a.mean_delta_v_loss_fraction,0);
end

function testAdvancedFieldsSurviveConfig(testCase)
mission=struct('payload_kg',100,'delta_v_budget_m_s',2000);
s=struct('name','S','propellant_name','LOX/RP1', ...
    'delta_v_fraction',1,'thrust_N',300e3,'nozzle_area_ratio',20, ...
    'diameter_m',2,'drag_model','shape_specific', ...
    'nose_cone',struct('shape','haack','length_m',3), ...
    'engine_mass_model',struct('mode','thesis_2014'), ...
    'solid_grain',struct('geometry','bates'));
cfg=make_launcher_config(mission,s);
verifyEqual(testCase,cfg.stages.drag_model,'shape_specific');
verifyEqual(testCase,cfg.stages.nose_cone.shape,'haack');
verifyEqual(testCase,cfg.stages.engine_mass_model.mode,'thesis_2014');
verifyEqual(testCase,cfg.stages.solid_grain.geometry,'bates');
end

function testUnifiedGuiEntrypointExists(testCase)
verifyEqual(testCase,exist('rocket_design_app','file'),2);
end


function testConstraintAwareThrottleRespondsToAxialLimit(testCase)
env=earth_constants();
stage=struct('thrust_N',500e3,'Isp_s',300,'CdA_m2',0, ...
    'diameter_m',2);
state=[env.Re;0;0;0;10000];
aero=struct('pressure_Pa',101325,'dynamic_pressure_Pa',0, ...
    'drag_N',0,'mach',0,'speed_of_sound_m_s',340,'rho_kg_m3',1.2);
[u,d]=constraint_aware_throttle(aero,state,stage,env, ...
    struct('max_axial_accel_g',2),struct('min_throttle',0.1));
verifyLessThan(testCase,u,1);
verifyGreaterThanOrEqual(testCase,u,0.1);
verifyTrue(testCase,d.limited);
end

function testConstraintControlledStageBurnsToPropellantEvent(testCase)
mission=struct('payload_kg',100,'delta_v_budget_m_s',1200, ...
    'orbit_altitude_km',100);
s=struct('name','S','propellant_name','HTPB/AP', ...
    'delta_v_fraction',1,'thrust_N',150e3,'nozzle_area_ratio',12, ...
    'diameter_m',1.5,'constraint_limits', ...
    struct('max_axial_accel_g',3), ...
    'constraint_control',struct('min_throttle',0.4));
cfg=make_launcher_config(mission,s);
mass=thesis_iterative_mass_model(cfg);
tcfg=trajectory_config_from_mass_result(cfg,mass);
m.target_alt=100e3; m.launch_lat=0;
p=struct('t_pitch',5,'pitch_kick',deg2rad(1),'kick_dur',1);
traj=simulate_gravity_turn(tcfg,m,p,mission.payload_kg);
verifyEqual(testCase,traj.stage_events(1).mass_burnout_kg, ...
    traj.m0-tcfg.stages(1).mp_kg,'RelTol',1e-10);
verifyLessThanOrEqual(testCase,min(traj.throttle),1);
verifyGreaterThanOrEqual(testCase,min(traj.throttle),0.4-1e-12);
end
