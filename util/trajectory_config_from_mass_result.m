function traj_cfg = trajectory_config_from_mass_result(cfg, mass_result, opts)
%TRAJECTORY_CONFIG_FROM_MASS_RESULT Adapt generalized sizing to 2D ascent.
%
% This adapter keeps the mass model independent from the trajectory model.
% Aerodynamics in the current trajectory solver are still low fidelity:
% each stage uses a constant Cd*A. If CdA_m2 is not supplied, it is derived
% from diameter_m and a constant reference Cd.
%
% opts.default_Cd defaults to 0.5 and is explicitly a temporary modelling
% assumption until the thesis Mach/nose-cone drag model is restored.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'default_Cd'), opts.default_Cd=0.5; end
validateattributes(opts.default_Cd,{'numeric'}, ...
    {'scalar','real','finite','positive'});

if numel(cfg.stages)~=numel(mass_result.stages)
    error('trajectory_config_from_mass_result:StageCount', ...
        'Configuration and mass result must have the same number of stages.');
end

N=numel(cfg.stages);
template=struct('name','','Isp_s',0,'thrust_N',0, ...
    'mp_kg',0,'ms_kg',0,'fs_struct',0,'CdA_m2',0);
stages=repmat(template,1,N);

for i=1:N
    source=cfg.stages(i);
    sized=mass_result.stages(i);

    cdA=NaN;
    if isfield(source,'CdA_m2') && isfinite(source.CdA_m2) && source.CdA_m2>=0
        cdA=source.CdA_m2;
    elseif isfield(source,'diameter_m') && isfinite(source.diameter_m) && source.diameter_m>0
        Cd=opts.default_Cd;
        if isfield(source,'Cd_ref') && isfinite(source.Cd_ref) && source.Cd_ref>0
            Cd=source.Cd_ref;
        end
        area=pi*(source.diameter_m^2)/4;
        cdA=Cd*area;
    end

    if ~isfinite(cdA)
        error('trajectory_config_from_mass_result:MissingAerodynamics', ...
            ['Stage %d (%s) requires CdA_m2 or a positive diameter_m. ', ...
             'The current coupled solver uses a constant-Cd placeholder.'], ...
            i,source.name);
    end

    stages(i).name=source.name;
    stages(i).Isp_s=source.Isp_s;
    stages(i).thrust_N=source.thrust_N;
    stages(i).mp_kg=sized.mp_kg;
    stages(i).ms_kg=sized.ms_kg;
    stages(i).fs_struct=sized.epsilon;
    stages(i).CdA_m2=cdA;
end

traj_cfg.name='GENERALIZED-COUPLED';
if isfield(cfg,'source'), traj_cfg.notes=cfg.source; end
traj_cfg.stages=stages;
end
