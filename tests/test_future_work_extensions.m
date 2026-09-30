function tests = test_future_work_extensions
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'util'));
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'validation'));
end

function testThesisGeometryAndSkinEquation(testCase)
stage=struct('diameter_m',2,'propulsion_type','liquid', ...
    'mixture_ratio_OF',3,'rho_oxidizer_kg_m3',1000, ...
    'rho_fuel_kg_m3',500);
g=thesis_stage_geometry_skin(stage,4000, ...
    struct('skin_thickness_m',0.003,'alloy_density_kg_m3',2700));
mox=3000; mfuel=1000;
V=(mox/1000+mfuel/500);
verifyEqual(testCase,g.propellant_volume_m3,V,'RelTol',1e-12);
verifyEqual(testCase,g.stage_internal_volume_m3,1.10*V,'RelTol',1e-12);
verifyEqual(testCase,g.cylinder_length_m, ...
    1.10*V/pi,'RelTol',1e-12);
verifyEqual(testCase,g.skin_mass_kg,2700*g.skin_area_m2*0.003, ...
    'RelTol',1e-12);
end

function testSkinMassMakesDiameterMatter(testCase)
stage=struct('name','Geometry liquid','propellant_name','LOX/H2', ...
    'propulsion_type','liquid','Isp_s',430,'thrust_N',300e3, ...
    'nozzle_area_ratio',50,'mixture_ratio_OF',3.8, ...
    'rho_oxidizer_kg_m3',1142,'rho_fuel_kg_m3',71, ...
    'diameter_m',3,'include_skin_mass',true, ...
    'skin_model',struct('skin_thickness_m',0.003));
m1=modern_stage_mer(stage,1000,10000);
stage.diameter_m=5;
m2=modern_stage_mer(stage,1000,10000);
verifyGreaterThan(testCase,m1.skin_kg,0);
verifyGreaterThan(testCase,m2.skin_kg,0);
verifyNotEqual(testCase,m1.skin_kg,m2.skin_kg);
verifyTrue(testCase,isfield(m1,'geometry'));
end

function testPressureAwareNozzleVacuumAndSeaLevel(testCase)
stage=struct('chamber_pressure_Pa',7e6,'nozzle_area_ratio',40, ...
    'gamma',1.22,'cstar_m_s',1800,'mass_flow_kg_s',100, ...
    'nozzle_half_angle_deg',15,'nozzle_wall_thickness_m',0.003, ...
    'nozzle_material_density_kg_m3',8200);
vac=pressure_aware_nozzle(stage,0);
sea=pressure_aware_nozzle(stage,101325);
verifyEqual(testCase,vac.exit_area_m2/vac.throat_area_m2,40, ...
    'RelTol',1e-12);
verifyGreaterThan(testCase,vac.exit_mach,1);
verifyLessThan(testCase,vac.exit_pressure_Pa,stage.chamber_pressure_Pa);
verifyGreaterThan(testCase,vac.thrust_N,sea.thrust_N);
verifyGreaterThan(testCase,vac.nozzle_shell_mass_kg,0);
verifyGreaterThan(testCase,vac.Isp_s,0);
end

function testPressureNozzleCanReplaceSolidEmpiricalNozzle(testCase)
stage=struct('name','solid','propellant_name','HTPB/AP', ...
    'propulsion_type','solid','Isp_s',270,'thrust_N',500e3, ...
    'nozzle_area_ratio',20,'mixture_ratio_OF',NaN, ...
    'diameter_m',2,'rho_oxidizer_kg_m3',1800, ...
    'pressure_nozzle',struct('enabled',true, ...
        'chamber_pressure_Pa',5e6,'gamma',1.2,'cstar_m_s',1500, ...
        'nozzle_wall_thickness_m',0.004, ...
        'nozzle_material_density_kg_m3',7800));
m=modern_stage_mer(stage,500,5000);
verifyGreaterThan(testCase,m.nozzle_kg,0);
verifyTrue(testCase,isfield(m,'pressure_nozzle'));
verifyEqual(testCase,m.nozzle_kg,m.pressure_nozzle.nozzle_shell_mass_kg, ...
    'RelTol',1e-12);
end

function testTrajectoryConstraintsPassAndFail(testCase)
traj.t=[0 1 2];
traj.v=[0 500 1000];
traj.h=[0 5000 10000];
traj.m=[1000 900 800];
traj.stage_index=[1 1 1];
traj.rho=[1.2 .7 .4];
traj.dynamic_pressure_Pa=0.5*traj.rho.*traj.v.^2;
traj.Cd=[.2 .25 .3];
vehicle.stages=struct('diameter_m',2,'thrust_N',200e3);
limits=struct('max_q_Pa',1e9,'max_heat_flux_W_m2',1e12, ...
    'max_bending_moment_Nm',1e12,'max_axial_accel_g',100);
opts=struct('nose_radius_m',.5,'angle_of_attack_rad',deg2rad(2), ...
    'bending_lever_arm_m',5);
c=evaluate_trajectory_constraints(traj,vehicle,limits,opts);
verifyTrue(testCase,c.all_pass);
verifyGreaterThan(testCase,c.max_q_Pa,0);
verifyGreaterThan(testCase,c.max_heat_flux_W_m2,0);
verifyGreaterThan(testCase,c.max_bending_moment_Nm,0);
verifyGreaterThan(testCase,c.max_axial_accel_g,0);

limits.max_q_Pa=1000;
c2=evaluate_trajectory_constraints(traj,vehicle,limits,opts);
verifyFalse(testCase,c2.all_pass);
verifyFalse(testCase,c2.pass.dynamic_pressure);
end

function testParallelTrajectoryAdapterClosesMass(testCase)
cfg=ariane5_2014_parallel_config('reported_optimum');
s=size_parallel_booster_launcher(cfg, ...
    struct('delta_v_match_tolerance_m_s',1500));
h=parallel_booster_trajectory_config(cfg,s, ...
    struct('interstage_coast_time_s',3));
verifyEqual(testCase,h.mass_closure_error_kg,0,'AbsTol',1e-6);
verifyEqual(testCase,h.coast_time_s(1),0);
verifyEqual(testCase,h.coast_time_s(2),3);
verifyEqual(testCase,h.stages(1).ms_kg, ...
    s.lower.booster_count*s.lower.booster.ms_kg,'RelTol',1e-12);
verifyEqual(testCase,h.stages(2).mp_kg, ...
    s.lower.performance.core_propellant_remaining_after_boosters_kg, ...
    'RelTol',1e-12);
verifyGreaterThan(testCase,h.stages(1).thrust_N,h.stages(2).thrust_N);
end

function testParallelAtmosphericTrajectoryAndConstraints(testCase)
cfg=ariane5_2014_parallel_config('reported_optimum');
s=size_parallel_booster_launcher(cfg, ...
    struct('delta_v_match_tolerance_m_s',1500));
opts=struct();
opts.trajectory_config=struct('interstage_coast_time_s',3);
opts.free_flight_opts=struct('rel_tol',5e-4,'abs_tol',1e-6, ...
    'mesh_points',31,'output_points',61,'max_nodes',6000);
opts.constraint_limits=struct('max_q_Pa',Inf, ...
    'max_heat_flux_W_m2',Inf,'max_axial_accel_g',Inf);
r=simulate_parallel_booster_trajectory(cfg,s,opts);
verifyGreaterThan(testCase,numel(r.atmospheric.t),2);
verifyEqual(testCase,r.mass_closure_error_kg,0,'AbsTol',1e-6);
verifyGreaterThanOrEqual(testCase,r.constraints.max_q_Pa,0);
verifyGreaterThanOrEqual(testCase,r.constraints.max_heat_flux_W_m2,0);
verifyTrue(testCase,r.constraints_pass);
fprintf(['ARIANE booster trajectory: Kn transition=%d, max-q %.1f kPa, ', ...
    'max heat %.1f kW/m^2, status=%s\n'], ...
    r.transition_detected,r.constraints.max_q_Pa/1000, ...
    r.constraints.max_heat_flux_W_m2/1000,r.status);
end


function testAdvancedStageFieldsSurviveConfigBuilder(testCase)
mission=struct('payload_kg',100,'delta_v_budget_m_s',2000);
s=struct('name','Advanced solid','propellant_name','HTPB/AP', ...
    'delta_v_fraction',1,'thrust_N',300e3,'nozzle_area_ratio',20, ...
    'diameter_m',2,'include_skin_mass',true, ...
    'skin_model',struct('skin_thickness_m',0.004), ...
    'pressure_nozzle',struct('enabled',true, ...
        'chamber_pressure_Pa',5e6,'gamma',1.2,'cstar_m_s',1500, ...
        'nozzle_wall_thickness_m',0.004, ...
        'nozzle_material_density_kg_m3',7800));
cfg=make_launcher_config(mission,s);
verifyTrue(testCase,cfg.stages(1).include_skin_mass);
verifyEqual(testCase,cfg.stages(1).skin_model.skin_thickness_m,0.004);
verifyTrue(testCase,cfg.stages(1).pressure_nozzle.enabled);
verifyEqual(testCase,cfg.stages(1).pressure_nozzle.chamber_pressure_Pa,5e6);
end


function testConstraintEvaluatorUsesZeroThrustDuringCoast(testCase)
traj.t=[0 1 2];
traj.v=[100 100 100];
traj.h=[1000 1000 1000];
traj.m=[1000 1000 1000];
traj.stage_index=[1 1 1];
traj.powered=[true false true];
traj.rho=[1 1 1];
traj.dynamic_pressure_Pa=0.5*traj.rho.*traj.v.^2;
traj.Cd=[0.2 0.2 0.2];

vehicle.stages=struct('diameter_m',2,'thrust_N',100e3);
c=evaluate_trajectory_constraints(traj,vehicle,struct(), ...
    struct('nose_radius_m',0.5));

verifyGreaterThan(testCase,c.thrust_N(1),0);
verifyEqual(testCase,c.thrust_N(2),0,'AbsTol',0);
verifyGreaterThan(testCase,c.thrust_N(3),0);
verifyFalse(testCase,c.powered(2));
verifyLessThan(testCase,c.axial_accel_g(2),0);
end

function testHistoricalCoastSamplesAreMarkedUnpowered(testCase)
cfg=vega_2014_trajectory_config();
p=simulate_thesis_2014_atmospheric_phase(cfg);
verifyEqual(testCase,numel(p.powered),numel(p.t));
if any(~p.powered)
    verifyTrue(testCase,all(p.stage_index(~p.powered)>=2));
end
end
