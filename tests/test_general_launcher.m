function tests = test_general_launcher
tests = functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));
end

function testCatalogSelectionAndCorrectedType(testCase)
mission=struct('payload_kg',1000,'delta_v_budget_m_s',8500, ...
    'orbit_altitude_km',200);
specs=two_stage_fixture();
cfg=make_launcher_config(mission,specs);
verifyEqual(testCase,numel(cfg.stages),2);
verifyEqual(testCase,cfg.stages(1).propulsion_type,'liquid');
verifyEqual(testCase,cfg.stages(2).propulsion_type,'liquid');
verifyEqual(testCase,cfg.stages(1).mixture_ratio_OF,2.27, ...
    'AbsTol',1e-12);
verifyEqual(testCase,cfg.stages(2).Isp_s,440);
end

function testGeneralTwoStageConvergence(testCase)
mission=struct('payload_kg',1000,'delta_v_budget_m_s',8500, ...
    'orbit_altitude_km',200);
cfg=make_launcher_config(mission,two_stage_fixture());
result=thesis_iterative_mass_model(cfg);
verifyTrue(testCase,result.converged);
verifyGreaterThan(testCase,result.GLOW_kg,mission.payload_kg);
verifyEqual(testCase,result.GLOW_kg,mission.payload_kg+ ...
    sum([result.stages.ms_kg])+sum([result.stages.mp_kg]), ...
    'RelTol',1e-10);
verifyEqual(testCase,result.stages(2).payload_above_kg, ...
    mission.payload_kg,'AbsTol',1e-10);
verifyLessThanOrEqual(testCase, ...
    max([result.stages.relative_structural_error]),1e-3);
end

function testStageDeltaVPhysics(testCase)
mission=struct('payload_kg',1000,'delta_v_budget_m_s',8500);
cfg=make_launcher_config(mission,two_stage_fixture());
r=thesis_iterative_mass_model(cfg);
for i=1:numel(r.stages)
    s=r.stages(i);
    m_before=s.section_initial_mass_kg;
    m_after=s.payload_above_kg+s.ms_kg;
    recovered=cfg.mission.g0*s.Isp_s*log(m_before/m_after);
    verifyEqual(testCase,recovered,s.delta_v_ms,'RelTol',1e-10);
    verifyEqual(testCase,s.ms_kg/(s.ms_kg+s.mp_kg), ...
        s.epsilon,'RelTol',1e-10);
end
end

function testArbitraryFiveStageAndOneStage(testCase)
m1=struct('payload_kg',75,'delta_v_budget_m_s',3000);
single=struct('name','Single solid stage', ...
    'propellant_name','custom','propulsion_type','solid', ...
    'Isp_s',290,'delta_v_fraction',1,'thrust_N',100e3, ...
    'nozzle_area_ratio',12,'epsilon0',0.12);
r1=thesis_iterative_mass_model(make_launcher_config(m1,single));
verifyEqual(testCase,numel(r1.stages),1);
verifyTrue(testCase,r1.converged);

m5=struct('payload_kg',75,'delta_v_budget_m_s',5000);
many=repmat(single,1,5);
for i=1:5
    many(i).name=sprintf('Stage %d',i);
    many(i).delta_v_fraction=0.2;
    many(i).thrust_N=100e3/2^(i-1);
end
r5=thesis_iterative_mass_model(make_launcher_config(m5,many));
verifyEqual(testCase,numel(r5.stages),5);
verifyTrue(testCase,r5.converged);
verifyEqual(testCase,r5.stages(5).payload_above_kg,75);
end

function testPropulsionAwareComponents(testCase)
mission=struct('payload_kg',500,'delta_v_budget_m_s',2000);
solid=struct('name','S','propellant_name','HTPB/AP', ...
    'delta_v_fraction',1,'thrust_N',800e3,'nozzle_area_ratio',25);
a=make_launcher_config(mission,solid);
m=modern_stage_mer(a.stages(1),500,5000);
verifyEqual(testCase,m.motor_casing_kg,675,'AbsTol',1e-12);
verifyEqual(testCase,m.fuel_tank_kg,0);
verifyEqual(testCase,m.engine_kg,0);
verifyGreaterThan(testCase,m.nozzle_kg,0);

liquid=struct('name','L','propellant_name','LOX/RP1', ...
    'delta_v_fraction',1,'thrust_N',800e3,'nozzle_area_ratio',25);
b=make_launcher_config(mission,liquid);
n=modern_stage_mer(b.stages(1),500,5000);
verifyEqual(testCase,n.fuel_tank_kg, ...
    0.0148*5000/(2.27+1),'RelTol',1e-12);
verifyEqual(testCase,n.motor_casing_kg,0);
verifyGreaterThan(testCase,n.engine_kg,0);
verifyEqual(testCase,n.nozzle_kg,0);
end

function testInvalidDeltaVAndUnknownPropellant(testCase)
mission=struct('payload_kg',1000,'delta_v_budget_m_s',8500);
s=two_stage_fixture();
s(1).delta_v_fraction=0.5;
verifyError(testCase,@()make_launcher_config(mission,s), ...
    'make_launcher_config:DeltaVFractions');
s=two_stage_fixture();
s(1).propellant_name='unregistered experimental formula';
verifyError(testCase,@()make_launcher_config(mission,s), ...
    'make_launcher_config:UnknownPropellant');
end

function testNoStructuralRootIsReported(testCase)
mission=struct('payload_kg',100,'delta_v_budget_m_s',20000);
single=struct('name','Overstressed solid stage', ...
    'propellant_name','HTPB/AP','delta_v_fraction',1, ...
    'thrust_N',100e3,'nozzle_area_ratio',12);
cfg=make_launcher_config(mission,single);
verifyError(testCase,@()thesis_iterative_mass_model(cfg), ...
    'thesis_iterative_mass_model:NoStructuralSolution');
end

function testProgrammaticEntryPoint(testCase)
mission=struct('payload_kg',1000,'delta_v_budget_m_s',8500);
[r,cfg]=run_thesis_sizing(mission,two_stage_fixture(), ...
    struct('show_plots',false));
verifyTrue(testCase,r.converged);
verifyEqual(testCase,numel(cfg.stages),2);
end

function specs = two_stage_fixture()
specs(1)=struct('name','LOX/RP1 core', ...
    'propellant_name','LOX/RP1','delta_v_fraction',0.55, ...
    'thrust_N',2.5e6,'nozzle_area_ratio',25, ...
    'Isp_s',295,'epsilon0',0.08);
specs(2)=struct('name','LOX/H2 upper', ...
    'propellant_name','LOX/H2','delta_v_fraction',0.45, ...
    'thrust_N',300e3,'nozzle_area_ratio',80, ...
    'Isp_s',440,'epsilon0',0.10);
end
