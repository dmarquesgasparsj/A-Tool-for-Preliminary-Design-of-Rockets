function dstatedt = equations_of_motion(t, state, env, stage, guidance)
% EQUATIONS_OF_MOTION — EDOs 2D polar para voo com *gravity turn* e arrasto.
% state = [r; theta; vr; vtheta; m]
% env   = struct com campos: mu, Re, g0
% stage = struct do estágio atual: thrust_N, Isp_s, CdA_m2
% guidance = função handle u = guidance(t, state) que devolve [ur, utheta] (vetor unitário de empuxo)

r      = state(1);
theta  = state(2); %#ok<NASGU>
vr     = state(3);
vtheta = state(4);
m      = state(5);

% Cinemática
v   = hypot(vr, vtheta);
if v > 1e-3
    ev_r   = vr / v;
    ev_th  = vtheta / v;
else
    ev_r  = 1.0;  % se v ~ 0, definimos direção arbitrária para evitar NaN
    ev_th = 0.0;
end

% Densidade/Arrasto
h   = max(0, r - env.Re);
rho = atmosphere(h);
D   = 0.5 * rho * v^2 * stage.CdA_m2; % magnitude do arrasto
Dr  = -D * ev_r;
Dth = -D * ev_th;

% Empuxo e direção de empuxo
u = guidance(t, state); % vetor unitário [ur, utheta]
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
