function [throttle,diag] = constraint_aware_throttle(aero,state,stage,env,limits,opts)
%CONSTRAINT_AWARE_THROTTLE Preliminary ascent-constraint control law.
%
% Converts the Future-Work trajectory constraints into a bounded throttle
% command. The controller is deliberately simple and transparent:
% - axial acceleration gives an exact instantaneous thrust ceiling;
% - q, heat flux and bending use soft-limit proportional throttle reduction.
%
% This is a conceptual guidance/throttle response, not flight-certified GNC.
% Directional guidance remains handled by the existing guidance function.
%
% limits fields (optional):
%   max_q_Pa, max_heat_flux_W_m2, max_bending_moment_Nm,
%   max_axial_accel_g
%
% opts:
%   min_throttle default 0.2
%   soft_fraction default 0.9
%   response_exponent default 1
%   nose_radius_m, angle_of_attack_rad, bending_lever_arm_m,
%   normal_force_slope_per_rad default 2
%   sutton_graves_k default 1.7415e-4

if nargin<5 || isempty(limits), limits=struct(); end
if nargin<6 || isempty(opts), opts=struct(); end
if ~isfield(opts,'min_throttle'), opts.min_throttle=0.2; end
if ~isfield(opts,'soft_fraction'), opts.soft_fraction=0.9; end
if ~isfield(opts,'response_exponent'), opts.response_exponent=1; end
if ~isfield(opts,'normal_force_slope_per_rad'), opts.normal_force_slope_per_rad=2; end
if ~isfield(opts,'sutton_graves_k'), opts.sutton_graves_k=1.7415e-4; end
if ~isfield(opts,'angle_of_attack_rad'), opts.angle_of_attack_rad=0; end
if ~isfield(opts,'bending_lever_arm_m'), opts.bending_lever_arm_m=NaN; end

validateattributes(opts.min_throttle,{'numeric'}, ...
    {'scalar','real','finite','>=',0,'<=',1});
validateattributes(opts.soft_fraction,{'numeric'}, ...
    {'scalar','real','finite','>',0,'<=',1});

m=max(state(5),eps);
Tnom=stage_thrust_at_ambient(stage,aero.pressure_Pa);
q=aero.dynamic_pressure_Pa;
v=aero.mach*aero.speed_of_sound_m_s;
rho=aero.rho_kg_m3;

candidates=1;
diag.dynamic_pressure_Pa=q;
diag.heat_flux_W_m2=NaN;
diag.bending_moment_Nm=NaN;
diag.unthrottled_axial_accel_g=(Tnom-aero.drag_N)/(m*env.g0);

if isfield(limits,'max_q_Pa') && isfinite(limits.max_q_Pa)
    candidates(end+1)=soft_limit_command(q,limits.max_q_Pa,opts); %#ok<AGROW>
end

if isfield(limits,'max_heat_flux_W_m2') && isfinite(limits.max_heat_flux_W_m2)
    Rn=NaN;
    if isfield(opts,'nose_radius_m'), Rn=opts.nose_radius_m; end
    if ~isfinite(Rn) && isfield(stage,'nose_cone') && ...
            isstruct(stage.nose_cone) && isfield(stage.nose_cone,'radius_m')
        Rn=stage.nose_cone.radius_m;
    end
    if ~isfinite(Rn) && isfield(stage,'diameter_m') && isfinite(stage.diameter_m)
        Rn=stage.diameter_m/2;
    end
    if isfinite(Rn) && Rn>0
        heat=opts.sutton_graves_k*sqrt(rho/Rn)*v^3;
        diag.heat_flux_W_m2=heat;
        candidates(end+1)=soft_limit_command(heat, ...
            limits.max_heat_flux_W_m2,opts); %#ok<AGROW>
    end
end

if isfield(limits,'max_bending_moment_Nm') && ...
        isfinite(limits.max_bending_moment_Nm) && ...
        isfinite(opts.bending_lever_arm_m)
    if isfield(stage,'reference_area_m2') && isfinite(stage.reference_area_m2)
        A=stage.reference_area_m2;
    elseif isfield(stage,'diameter_m') && isfinite(stage.diameter_m)
        A=pi*stage.diameter_m^2/4;
    else
        A=NaN;
    end
    if isfinite(A)
        normal=q*A*opts.normal_force_slope_per_rad* ...
            abs(opts.angle_of_attack_rad);
        bend=normal*opts.bending_lever_arm_m;
        diag.bending_moment_Nm=bend;
        candidates(end+1)=soft_limit_command(bend, ...
            limits.max_bending_moment_Nm,opts); %#ok<AGROW>
    end
end

if isfield(limits,'max_axial_accel_g') && isfinite(limits.max_axial_accel_g)
    Tmax=limits.max_axial_accel_g*env.g0*m+aero.drag_N;
    candidates(end+1)=max(0,min(1,Tmax/max(Tnom,eps))); %#ok<AGROW>
end

raw=min(candidates);
throttle=max(opts.min_throttle,min(1,raw));
diag.raw_command=raw;
diag.throttle=throttle;
diag.limited=throttle<1-1e-12;
diag.model_status=['Preliminary 2026 constraint-aware throttle law; ', ...
    'not flight-certified guidance or structural control.'];
end

function u=soft_limit_command(value,limit,opts)
if ~isfinite(limit) || limit<=0
    u=1;
    return;
end
start=opts.soft_fraction*limit;
if value<=start
    u=1;
else
    u=(limit/max(value,eps))^opts.response_exponent;
    u=max(0,min(1,u));
end
end
