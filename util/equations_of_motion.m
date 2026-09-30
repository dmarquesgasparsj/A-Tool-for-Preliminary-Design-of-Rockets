function dstatedt = equations_of_motion(t, state, env, stage, guidance)
% EQUATIONS_OF_MOTION — EDOs 2D polar para voo com *gravity turn* e arrasto.
% state = [r; theta; vr; vtheta; m]
% env   = struct com campos: mu, Re, g0
% stage = struct do estágio atual: thrust_N, Isp_s, CdA_m2 and optional thrust_misalignment_rad
% guidance = função handle u = guidance(t, state) que devolve [ur, utheta] (vetor unitário de empuxo)

r      = state(1);
theta  = state(2); %#ok<NASGU>
vr     = state(3);
vtheta = state(4);
m      = state(5);

% Kinematics are inertial, but aerodynamic forces depend on velocity
% relative to the co-rotating atmosphere.
v = hypot(vr,vtheta);
air = atmosphere_relative_velocity_2d(r,vr,vtheta,env);
if air.speed_m_s > 1e-3
    ev_r_air = air.vr_m_s / air.speed_m_s;
    ev_th_air = air.vtheta_m_s / air.speed_m_s;
else
    ev_r_air = 1.0;
    ev_th_air = 0.0;
end

% Aerodynamics
h = max(0, r - env.Re);
aero = aerodynamic_drag(stage,h,air.speed_m_s);
D = aero.drag_N;
Dr = -D * ev_r_air;
Dth = -D * ev_th_air;

% Empuxo e direção de empuxo
u = guidance(t, state); % vetor unitário [ur, utheta]
if isfield(stage,'thrust_misalignment_rad') && ...
        ~isempty(stage.thrust_misalignment_rad)
    u=apply_thrust_misalignment(u,stage.thrust_misalignment_rad);
end
T   = stage.thrust_N;
Tr  = T * u(1);
Tth = T * u(2);

% Gravidade
g_r = env.mu / r^2;

% Equações
ar     = (Tr + Dr)/m - g_r + (vtheta^2)/r;
atheta = (Tth + Dth)/m - (vr*vtheta)/r;

mdot = -T / (stage.Isp_s * env.g0); % consumo de massa

dstatedt = [vr; vtheta/r; ar; atheta; mdot];
end
