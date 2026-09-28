function traj_cfg = trajectory_config_from_mass_result(cfg, mass_result, opts)
%TRAJECTORY_CONFIG_FROM_MASS_RESULT Adapt generalized sizing to 2D ascent.
%
% The preferred modern path uses the thesis Eq. (3.49) Mach-dependent Cd
% whenever a stage diameter is available. Explicit CdA_m2 remains supported
% for backwards compatibility with the earlier constant-drag reconstruction.
%
% opts.drag_model:
%   'auto' (default)            -> thesis polynomial when diameter exists,
%                                  otherwise explicit constant CdA
%   'thesis_mach_polynomial'    -> require diameter/reference area
%   'constant_cda'              -> use explicit CdA or Cd_ref*area
%
% opts.default_Cd is used only by constant_cda when deriving CdA.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'default_Cd'), opts.default_Cd=0.5; end
if ~isfield(opts,'drag_model'), opts.drag_model='auto'; end
validateattributes(opts.default_Cd,{'numeric'}, ...
    {'scalar','real','finite','positive'});
policy=lower(char(opts.drag_model));
if ~ismember(policy,{'auto','thesis_mach_polynomial','constant_cda'})
    error('trajectory_config_from_mass_result:DragModel', ...
        'Unknown drag model policy: %s.',policy);
end

if numel(cfg.stages)~=numel(mass_result.stages)
    error('trajectory_config_from_mass_result:StageCount', ...
        'Configuration and mass result must have the same number of stages.');
end

N=numel(cfg.stages);
template=struct('name','','Isp_s',0,'thrust_N',0, ...
    'mp_kg',0,'ms_kg',0,'fs_struct',0,'CdA_m2',NaN, ...
    'reference_area_m2',NaN,'diameter_m',NaN, ...
    'drag_model','constant_cda');
stages=repmat(template,1,N);

for i=1:N
    source=cfg.stages(i);
    sized=mass_result.stages(i);

    has_diameter=isfield(source,'diameter_m') && ...
        isfinite(source.diameter_m) && source.diameter_m>0;
    has_cda=isfield(source,'CdA_m2') && ...
        isfinite(source.CdA_m2) && source.CdA_m2>0;

    if strcmp(policy,'auto')
        if has_diameter
            model='thesis_mach_polynomial';
        elseif has_cda
            model='constant_cda';
        else
            model='';
        end
    else
        model=policy;
    end

    area=NaN;
    cdA=NaN;
    diameter=NaN;
    if has_diameter
        diameter=source.diameter_m;
        area=pi*diameter^2/4;
    end

    switch model
        case 'thesis_mach_polynomial'
            if ~has_diameter
                error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                    ['Stage %d (%s) needs diameter_m for the thesis ', ...
                     'Mach-dependent drag model.'],i,source.name);
            end
            % CdA is retained only as a nominal compatibility value.
            cdA=opts.default_Cd*area;

        case 'constant_cda'
            if has_cda
                cdA=source.CdA_m2;
            elseif has_diameter
                Cd=opts.default_Cd;
                if isfield(source,'Cd_ref') && ...
                        isfinite(source.Cd_ref) && source.Cd_ref>0
                    Cd=source.Cd_ref;
                end
                cdA=Cd*area;
            else
                error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                    ['Stage %d (%s) requires CdA_m2 or a positive ', ...
                     'diameter_m.'],i,source.name);
            end

        otherwise
            error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                'Stage %d (%s) has no usable aerodynamic definition.', ...
                i,source.name);
    end

    stages(i).name=source.name;
    stages(i).Isp_s=source.Isp_s;
    stages(i).thrust_N=source.thrust_N;
    stages(i).mp_kg=sized.mp_kg;
    stages(i).ms_kg=sized.ms_kg;
    stages(i).fs_struct=sized.epsilon;
    stages(i).CdA_m2=cdA;
    stages(i).reference_area_m2=area;
    stages(i).diameter_m=diameter;
    stages(i).drag_model=model;
end

traj_cfg.name='GENERALIZED-COUPLED';
if isfield(cfg,'source'), traj_cfg.notes=cfg.source; end
traj_cfg.stages=stages;

last_d=stages(end).diameter_m;
if isfinite(last_d) && last_d>0
    % Thesis text defines Kn characteristic length as nose/base radius.
    traj_cfg.knudsen_characteristic_length_m=last_d/2;
else
    traj_cfg.knudsen_characteristic_length_m=NaN;
end
traj_cfg.knudsen_transition_threshold=5;
end
