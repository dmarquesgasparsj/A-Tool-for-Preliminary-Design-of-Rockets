function aero = aerodynamic_drag(stage,h,v)
%AERODYNAMIC_DRAG Evaluate current launcher drag model at one state.
%
% Supported policies:
%   constant_cda             D = q * CdA_m2 (legacy modern reconstruction)
%   thesis_mach_polynomial   Cd(M) from thesis Eq. 3.49 and reference area
%   shape_specific           Appendix-A profile + modified-Newtonian high-Mach drag
%
% Shape-specific drag is a documented 2026 extension; thesis mode remains
% available unchanged for historical regression.

validateattributes(h,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(v,{'numeric'},{'scalar','real','finite','nonnegative'});
model='constant_cda';
if isfield(stage,'drag_model') && ~isempty(stage.drag_model)
    model=lower(char(stage.drag_model));
end

switch model
    case 'constant_cda'
        [rho,a,T,P]=atmosphere(h);
        if ~isfield(stage,'CdA_m2') || ~isfinite(stage.CdA_m2)
            error('aerodynamic_drag:MissingCdA','constant_cda requires CdA_m2.');
        end
        M=v/max(a,eps);
        if isfield(stage,'reference_area_m2') && isfinite(stage.reference_area_m2) ...
                && stage.reference_area_m2>0
            A=stage.reference_area_m2;
            Cd=stage.CdA_m2/A;
        else
            A=NaN;
            Cd=NaN;
        end
        q=0.5*rho*v^2;
        D=q*stage.CdA_m2;

    case 'thesis_mach_polynomial'
        atm=thesis_extended_atmosphere(h,v);
        rho=atm.rho_kg_m3;
        a=atm.speed_of_sound_m_s;
        T=atm.temperature_K;
        P=atm.pressure_Pa;
        M=atm.mach;
        Cd=thesis_cd_mach(M);
        if ~isfield(stage,'reference_area_m2') || ...
                ~isfinite(stage.reference_area_m2) || stage.reference_area_m2<=0
            error('aerodynamic_drag:MissingReferenceArea', ...
                'thesis_mach_polynomial requires reference_area_m2.');
        end
        A=stage.reference_area_m2;
        q=0.5*rho*v^2;
        D=q*Cd*A;

    case {'shape_specific','shape_specific_modified_newtonian'}
        atm=thesis_extended_atmosphere(h,v);
        rho=atm.rho_kg_m3;
        a=atm.speed_of_sound_m_s;
        T=atm.temperature_K;
        P=atm.pressure_Pa;
        M=atm.mach;
        if ~isfield(stage,'nose_cone') || ~isstruct(stage.nose_cone)
            error('aerodynamic_drag:MissingNoseCone', ...
                'shape_specific requires stage.nose_cone.');
        end
        nc=stage.nose_cone;
        if ~isfield(nc,'shape') || ~isfield(nc,'length_m')
            error('aerodynamic_drag:MissingNoseCone', ...
                'stage.nose_cone requires shape and length_m.');
        end
        if isfield(nc,'radius_m') && isfinite(nc.radius_m) && nc.radius_m>0
            R=nc.radius_m;
        elseif isfield(stage,'diameter_m') && isfinite(stage.diameter_m)
            R=stage.diameter_m/2;
        else
            error('aerodynamic_drag:MissingNoseConeRadius', ...
                'Provide nose_cone.radius_m or stage.diameter_m.');
        end
        dopts=struct();
        if isfield(nc,'drag_options') && isstruct(nc.drag_options)
            dopts=nc.drag_options;
        end
        if isfield(nc,'geometry_options') && isstruct(nc.geometry_options)
            dopts.geometry_options=nc.geometry_options;
        end
        [Cd,shape_detail]=nose_cone_drag_coefficient( ...
            M,nc.shape,nc.length_m,R,dopts);
        A=pi*R^2;
        q=0.5*rho*v^2;
        D=q*Cd*A;

    otherwise
        error('aerodynamic_drag:UnknownModel','Unknown drag model: %s',model);
end

aero.drag_N=D;
aero.dynamic_pressure_Pa=q;
aero.Cd=Cd;
aero.mach=M;
aero.rho_kg_m3=rho;
aero.speed_of_sound_m_s=a;
aero.temperature_K=T;
aero.pressure_Pa=P;
aero.reference_area_m2=A;
aero.model=model;
if exist('shape_detail','var'), aero.shape_detail=shape_detail; end
end
