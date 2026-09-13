function tests = test_core
tests = functiontests(localfunctions);
end

function setupOnce(~)
repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo_root, 'configs'));
addpath(fullfile(repo_root, 'util'));
end

function testConfigNormalization(testCase)
cfg = validate_config(demo_config());
verifyEqual(testCase, numel(cfg.stages), 2);
verifyGreaterThan(testCase, cfg.stages(1).ms_kg, 0);
verifyEqual(testCase, cfg.stages(1).fs_struct, 0.08, 'AbsTol', 1e-12);
end

function testTrajectoryMassAccounting(testCase)
cfg = validate_config(demo_config());
mission.target_alt = 200e3;
mission.launch_lat = deg2rad(38.65);
params.t_pitch = 20;
params.pitch_kick = deg2rad(3);
params.kick_dur = 1;
payload = 1000;

traj = simulate_gravity_turn(cfg, mission, params, payload);
expected_m0 = payload + sum([cfg.stages.mp_kg]) + sum([cfg.stages.ms_kg]);
verifyEqual(testCase, traj.m0, expected_m0, 'RelTol', 1e-12);
verifyEqual(testCase, numel(traj.stage_events), numel(cfg.stages));
verifyEqual(testCase, traj.stage_events(1).mass_after_sep_kg, ...
    traj.stage_events(1).mass_burnout_kg - cfg.stages(1).ms_kg, ...
    'RelTol', 1e-12);
verifyEqual(testCase, traj.stage_index(end), numel(cfg.stages));
end

function testInvalidStructuralFractionRejected(testCase)
cfg = demo_config();
cfg.stages(1).fs_struct = 1.2;
verifyError(testCase, @() validate_config(cfg), ...
    'validate_config:InvalidStructuralFraction');
end
