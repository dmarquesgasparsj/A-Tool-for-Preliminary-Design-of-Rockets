function hcfg = parallel_booster_trajectory_config(cfg,sizing,opts)
%PARALLEL_BOOSTER_TRAJECTORY_CONFIG Convert booster sizing to flight phases.
%
% The parallel booster/core burn is represented as a virtual "zeroth stage":
%   - propellant = booster propellant + core propellant burned during overlap
%   - dry mass dropped = booster dry mass only
%   - thrust = core thrust + all booster thrust
% Then the remaining core is represented as a normal serial stage.
%
% This lets the existing atmospheric/Knudsen/TPBVP machinery propagate the
% generalized booster system without pretending the boosters are serial.
%
% The equivalent diameter of the virtual phase defaults to a sum-of-frontal-
% areas approximation:
%   Aeq = Acore + N*Abooster.
%
% opts:
%   gravity_turn_altitude_m        default 500
%   gravity_turn_seed_gamma_deg    default 89.5
%   knudsen_threshold              default 5
%   equivalent_area_mode           'sum_frontal' (default)
%   interstage_coast_time_s        default from cfg.coast_time_s, else 0

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'gravity_turn_altitude_m'), opts.gravity_turn_altitude_m=500; end
if ~isfield(opts,'gravity_turn_seed_gamma_deg'), opts.gravity_turn_seed_gamma_deg=89.5; end
if ~isfield(opts,'knudsen_threshold'), opts.knudsen_threshold=5; end
if ~isfield(opts,'equivalent_area_mode'), opts.equivalent_area_mode='sum_frontal'; end
if ~isfield(opts,'interstage_coast_time_s')
    if isfield(cfg,'coast_time_s') && ~isempty(cfg.coast_time_s)
        opts.interstage_coast_time_s=cfg.coast_time_s;
    else
        opts.interstage_coast_time_s=0;
    end
end

core=sizing.lower.core;
booster=sizing.lower.booster;
perf=sizing.lower.performance;
n=booster.count;
g0=cfg.mission.g0;

overlap_core=perf.core_propellant_burned_with_boosters_kg;
core_remaining=perf.core_propellant_remaining_after_boosters_kg;
tb0=perf.booster_burn_time_s;
tb1=max(0,perf.core_burn_time_s-tb0);
booster_prop_total=n*booster.mp_kg;
booster_dry_total=n*booster.ms_kg;
phase0_prop=booster_prop_total+overlap_core;
phase0_mdot=phase0_prop/tb0;
phase0_thrust=core.thrust_N+n*booster.thrust_N;
phase0_isp=phase0_thrust/(phase0_mdot*g0);

switch lower(char(opts.equivalent_area_mode))
    case 'sum_frontal'
        Aeq=pi*core.diameter_m^2/4 + n*pi*booster.diameter_m^2/4;
        d0=sqrt(4*Aeq/pi);
    otherwise
        error('parallel_booster_trajectory_config:AreaMode', ...
            'Unknown equivalent_area_mode: %s.',char(opts.equivalent_area_mode));
end

template=struct('name','','Isp_s',0,'thrust_N',0,'mp_kg',0, ...
    'ms_kg',0,'burn_time_s',0,'diameter_m',0);
Nupper=numel(sizing.upper.stages);
stages=repmat(template,1,2+Nupper);

stages(1).name='Virtual zeroth stage: core + boosters';
stages(1).Isp_s=phase0_isp;
stages(1).thrust_N=phase0_thrust;
stages(1).mp_kg=phase0_prop;
stages(1).ms_kg=booster_dry_total;
stages(1).burn_time_s=tb0;
stages(1).diameter_m=d0;

stages(2).name=[core.name ' after booster jettison'];
stages(2).Isp_s=core.Isp_s;
stages(2).thrust_N=core.thrust_N;
stages(2).mp_kg=core_remaining;
stages(2).ms_kg=core.ms_kg;
stages(2).burn_time_s=tb1;
stages(2).diameter_m=core.diameter_m;
if isfield(cfg.stages(1),'pressure_nozzle')
    stages(2).pressure_nozzle=cfg.stages(1).pressure_nozzle;
end

for i=1:Nupper
    src=cfg.stages(i+1);
    sized=sizing.upper.stages(i);
    j=i+2;
    stages(j).name=src.name;
    stages(j).Isp_s=src.Isp_s;
    stages(j).thrust_N=src.thrust_N;
    stages(j).mp_kg=sized.mp_kg;
    stages(j).ms_kg=sized.ms_kg;
    if isfield(src,'burn_time_s') && isfinite(src.burn_time_s) && src.burn_time_s>0
        stages(j).burn_time_s=src.burn_time_s;
    else
        stages(j).burn_time_s=sized.mp_kg*src.Isp_s*g0/src.thrust_N;
    end
    stages(j).diameter_m=src.diameter_m;
    if isfield(src,'pressure_nozzle')
        stages(j).pressure_nozzle=src.pressure_nozzle;
    end
end

hcfg.name=[cfg.name '-PARALLEL-TRAJECTORY'];
hcfg.stages=stages;
hcfg.payload_kg=cfg.mission.payload_kg;
hcfg.target_altitude_m=cfg.mission.orbit_altitude_km*1e3;
hcfg.gravity_turn_altitude_m=opts.gravity_turn_altitude_m;
hcfg.gravity_turn_seed_gamma_rad=deg2rad(opts.gravity_turn_seed_gamma_deg);
hcfg.knudsen_threshold=opts.knudsen_threshold;
hcfg.knudsen_characteristic_length_m=stages(end).diameter_m/2;

% No coast at booster jettison: the core is already burning. Normal coast
% time applies after the core and between subsequent serial upper stages.
ntrans=numel(stages)-1;
coast=zeros(1,ntrans);
if ntrans>=2
    raw=opts.interstage_coast_time_s;
    if isscalar(raw)
        coast(2:end)=raw;
    else
        raw=reshape(raw,1,[]);
        if numel(raw)==ntrans-1
            coast(2:end)=raw;
        elseif numel(raw)==ntrans
            coast=raw;
            coast(1)=0;
        else
            error('parallel_booster_trajectory_config:CoastSize', ...
                'Interstage coast must be scalar or match serial transitions.');
        end
    end
end
hcfg.coast_time_s=coast;
hcfg.initial_mass_kg=sum([stages.mp_kg])+sum([stages.ms_kg])+hcfg.payload_kg;
hcfg.sizing_GLOW_kg=sizing.GLOW_kg;
hcfg.mass_closure_error_kg=hcfg.initial_mass_kg-sizing.GLOW_kg;
hcfg.virtual_phase.equivalent_diameter_m=d0;
hcfg.virtual_phase.reference_area_m2=pi*d0^2/4;
hcfg.virtual_phase.core_propellant_overlap_kg=overlap_core;
hcfg.virtual_phase.booster_propellant_kg=booster_prop_total;
hcfg.virtual_phase.booster_dry_drop_kg=booster_dry_total;
hcfg.source=['2026 booster-trajectory adapter using a virtual thesis ', ...
    '"zeroth stage" plus remaining core stage.'];
end
