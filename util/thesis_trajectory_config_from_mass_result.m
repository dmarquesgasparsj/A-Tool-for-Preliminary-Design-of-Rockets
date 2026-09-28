function hcfg = thesis_trajectory_config_from_mass_result(cfg,mass_result,opts)
%THESIS_TRAJECTORY_CONFIG_FROM_MASS_RESULT Build historical trajectory input.
%
% Converts the generalized modern mass result to the explicit configuration
% required by simulate_thesis_2014_atmospheric_phase(). Burn time is derived
% from thrust/Isp unless a stage supplies burn_time_s explicitly.
%
% This adapter does not change the mass model. It only prepares a trajectory
% case with documented assumptions.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'gravity_turn_altitude_m'), opts.gravity_turn_altitude_m=500; end
if ~isfield(opts,'gravity_turn_seed_gamma_deg'), opts.gravity_turn_seed_gamma_deg=89.5; end
if ~isfield(opts,'knudsen_threshold'), opts.knudsen_threshold=5; end
if ~isfield(opts,'g0'), opts.g0=9.80665; end

if numel(cfg.stages)~=numel(mass_result.stages)
    error('thesis_trajectory_config_from_mass_result:StageCount', ...
        'Configuration and mass result stage counts differ.');
end
N=numel(cfg.stages);
template=struct('name','','Isp_s',0,'thrust_N',0,'mp_kg',0, ...
    'ms_kg',0,'burn_time_s',0,'diameter_m',0);
stages=repmat(template,1,N);

for i=1:N
    src=cfg.stages(i);
    sized=mass_result.stages(i);
    if ~isfield(src,'diameter_m') || ~isfinite(src.diameter_m) || src.diameter_m<=0
        error('thesis_trajectory_config_from_mass_result:MissingDiameter', ...
            'Stage %d (%s) requires diameter_m for drag and Knudsen.',i,src.name);
    end
    if isfield(src,'burn_time_s') && isfinite(src.burn_time_s) && src.burn_time_s>0
        tb=src.burn_time_s;
    else
        mdot=src.thrust_N/(src.Isp_s*opts.g0);
        tb=sized.mp_kg/mdot;
    end
    stages(i).name=src.name;
    stages(i).Isp_s=src.Isp_s;
    stages(i).thrust_N=src.thrust_N;
    stages(i).mp_kg=sized.mp_kg;
    stages(i).ms_kg=sized.ms_kg;
    stages(i).burn_time_s=tb;
    stages(i).diameter_m=src.diameter_m;
end

hcfg.stages=stages;
hcfg.payload_kg=cfg.mission.payload_kg;
hcfg.gravity_turn_altitude_m=opts.gravity_turn_altitude_m;
hcfg.gravity_turn_seed_gamma_rad=deg2rad(opts.gravity_turn_seed_gamma_deg);
hcfg.knudsen_threshold=opts.knudsen_threshold;
hcfg.knudsen_characteristic_length_m=stages(end).diameter_m/2;
hcfg.source=['Adapter from generalized mass model to historical 2014 ', ...
    'atmospheric/TPBVP trajectory reconstruction.'];
end
