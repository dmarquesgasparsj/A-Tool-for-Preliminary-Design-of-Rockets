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
%   'shape_specific'             -> Appendix-A nose profile + 2026 drag extension
%
% opts.default_Cd is used only by constant_cda when deriving CdA.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'default_Cd'), opts.default_Cd=0.5; end
if ~isfield(opts,'drag_model'), opts.drag_model='auto'; end
validateattributes(opts.default_Cd,{'numeric'}, ...
    {'scalar','real','finite','positive'});
policy=lower(char(opts.drag_model));
if ~ismember(policy,{'auto','thesis_mach_polynomial','constant_cda','shape_specific','shape_specific_modified_newtonian'})
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
    'drag_model','constant_cda','thrust_misalignment_rad',0, ...
    'nose_cone',struct(),'pressure_nozzle',struct(), ...
    'constraint_limits',struct(),'constraint_control',struct(),'throttle',1, ...
    'design_epsilon',NaN);
stages=repmat(template,1,N);

for i=1:N
    source=cfg.stages(i);
    sized=mass_result.stages(i);

    has_diameter=isfield(source,'diameter_m') && ...
        isfinite(source.diameter_m) && source.diameter_m>0;
    has_cda=isfield(source,'CdA_m2') && ...
        isfinite(source.CdA_m2) && source.CdA_m2>0;
    has_reference_area=isfield(source,'reference_area_m2') && ...
        isfinite(source.reference_area_m2) && source.reference_area_m2>0;

    if strcmp(policy,'auto')
        configured='';
        if isfield(source,'drag_model') && ~isempty(source.drag_model)
            configured=lower(char(source.drag_model));
        end
        if any(strcmp(configured,{'constant_cda','thesis_mach_polynomial', ...
                'shape_specific','shape_specific_modified_newtonian'}))
            model=configured;
        elseif has_diameter || has_reference_area
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
    end
    if has_reference_area
        area=source.reference_area_m2;
    elseif has_diameter
        area=pi*diameter^2/4;
    end

    switch model
        case 'thesis_mach_polynomial'
            if ~isfinite(area) || area<=0
                error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                    ['Stage %d (%s) needs reference_area_m2 or diameter_m ', ...
                     'for the thesis Mach-dependent drag model.'],i,source.name);
            end
            % CdA is retained only as a nominal compatibility value.
            cdA=opts.default_Cd*area;

        case {'shape_specific','shape_specific_modified_newtonian'}
            if ~isfield(source,'nose_cone') || ~isstruct(source.nose_cone) || ...
                    isempty(fieldnames(source.nose_cone))
                error('trajectory_config_from_mass_result:MissingNoseCone', ...
                    'Stage %d (%s) requires nose_cone for shape-specific drag.', ...
                    i,source.name);
            end
            if isfield(source.nose_cone,'radius_m') && ...
                    isfinite(source.nose_cone.radius_m) && source.nose_cone.radius_m>0
                area=pi*source.nose_cone.radius_m^2;
            elseif has_diameter
                area=pi*source.diameter_m^2/4;
            else
                error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                    'Shape-specific drag requires nose radius or diameter.');
            end
            cdA=opts.default_Cd*area;
            model='shape_specific';

        case 'constant_cda'
            if has_cda
                cdA=source.CdA_m2;
            elseif isfinite(area) && area>0
                Cd=opts.default_Cd;
                if isfield(source,'Cd_ref') && ...
                        isfinite(source.Cd_ref) && source.Cd_ref>0
                    Cd=source.Cd_ref;
                end
                cdA=Cd*area;
            else
                error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                    ['Stage %d (%s) requires CdA_m2, reference_area_m2 ', ...
                     'or a positive diameter_m.'],i,source.name);
            end

        otherwise
            error('trajectory_config_from_mass_result:MissingAerodynamics', ...
                'Stage %d (%s) has no usable aerodynamic definition.', ...
                i,source.name);
    end

    stages(i).name=source.name;
    stages(i).Isp_s=source.Isp_s;
    stages(i).thrust_N=source.thrust_N;
    if isfield(sized,'usable_propellant_kg')
        stages(i).mp_kg=sized.usable_propellant_kg;
    else
        stages(i).mp_kg=sized.mp_kg;
    end
    reserve=0;
    if isfield(sized,'reserve_propellant_kg')
        reserve=sized.reserve_propellant_kg;
    end
    % Reserve propellant remains aboard at burnout and is therefore carried
    % with the jettisoned/non-burned mass in the trajectory representation.
    stages(i).ms_kg=sized.ms_kg+reserve;
    stages(i).design_epsilon=sized.epsilon;
    denom=stages(i).ms_kg+stages(i).mp_kg;
    if denom>0
        stages(i).fs_struct=stages(i).ms_kg/denom;
    else
        stages(i).fs_struct=0;
    end
    stages(i).CdA_m2=cdA;
    stages(i).reference_area_m2=area;
    stages(i).diameter_m=diameter;
    stages(i).drag_model=model;
    if isfield(source,'nose_cone') && isstruct(source.nose_cone)
        stages(i).nose_cone=source.nose_cone;
    end
    if isfield(source,'pressure_nozzle') && isstruct(source.pressure_nozzle)
        stages(i).pressure_nozzle=source.pressure_nozzle;
    end
    if isfield(source,'constraint_limits') && isstruct(source.constraint_limits)
        stages(i).constraint_limits=source.constraint_limits;
    end
    if isfield(source,'constraint_control') && isstruct(source.constraint_control)
        stages(i).constraint_control=source.constraint_control;
    end
    if isfield(source,'throttle') && ~isempty(source.throttle)
        stages(i).throttle=source.throttle;
    end
    if isfield(source,'thrust_misalignment_rad') && ...
            isfinite(source.thrust_misalignment_rad)
        stages(i).thrust_misalignment_rad=source.thrust_misalignment_rad;
    end
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
