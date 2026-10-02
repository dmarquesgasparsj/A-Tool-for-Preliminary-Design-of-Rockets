function dstatedt = equations_of_motion(t,state,env,stage,guidance)
%EQUATIONS_OF_MOTION Generalized 2D polar ascent equations.
% state = [r; theta; vr; vtheta; m]
%
% Optional stage capabilities:
%   pressure_nozzle       ambient-pressure-dependent thrust
%   thrust_misalignment_rad
%   throttle              scalar [0,1] or function handle f(t,state)
%   constraint_limits     passed to constraint_aware_throttle
%   constraint_control    controller options

r=state(1);
vr=state(3);
vtheta=state(4);
m=max(state(5),eps);

% Aerodynamics use the velocity relative to the co-rotating atmosphere.
air=atmosphere_relative_velocity_2d(r,vr,vtheta,env);
if air.speed_m_s>1e-3
    ev_r_air=air.vr_m_s/air.speed_m_s;
    ev_th_air=air.vtheta_m_s/air.speed_m_s;
else
    ev_r_air=1;
    ev_th_air=0;
end
h=max(0,r-env.Re);
aero=aerodynamic_drag(stage,h,air.speed_m_s);
D=aero.drag_N;
Dr=-D*ev_r_air;
Dth=-D*ev_th_air;

% Guidance and optional deterministic pointing error.
u=guidance(t,state);
if isfield(stage,'thrust_misalignment_rad') && ...
        ~isempty(stage.thrust_misalignment_rad)
    u=apply_thrust_misalignment(u,stage.thrust_misalignment_rad);
end

% Pressure-aware nominal thrust when configured.
[Tnom,thrust_detail]=stage_thrust_at_ambient(stage,aero.pressure_Pa);
throttle=1;
if isfield(stage,'throttle') && ~isempty(stage.throttle)
    if isa(stage.throttle,'function_handle')
        throttle=stage.throttle(t,state);
    else
        throttle=stage.throttle;
    end
    validateattributes(throttle,{'numeric'}, ...
        {'scalar','real','finite','>=',0,'<=',1});
end
if isfield(stage,'constraint_limits') && isstruct(stage.constraint_limits) && ...
        ~isempty(fieldnames(stage.constraint_limits))
    ctrl=struct();
    if isfield(stage,'constraint_control') && isstruct(stage.constraint_control)
        ctrl=stage.constraint_control;
    end
    [uconstraint,~]=constraint_aware_throttle( ...
        aero,state,stage,env,stage.constraint_limits,ctrl);
    throttle=min(throttle,uconstraint);
end

T=Tnom*throttle;
Tr=T*u(1);
Tth=T*u(2);

g_r=env.mu/r^2;
ar=(Tr+Dr)/m-g_r+(vtheta^2)/r;
atheta=(Tth+Dth)/m-(vr*vtheta)/r;

Isp=stage.Isp_s;
if isstruct(thrust_detail) && isfield(thrust_detail,'Isp_s') && ...
        isfinite(thrust_detail.Isp_s) && thrust_detail.Isp_s>0
    Isp=thrust_detail.Isp_s;
end
mdot=-T/(Isp*env.g0);

dstatedt=[vr;vtheta/r;ar;atheta;mdot];
end
