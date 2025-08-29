function traj = simulate_gravity_turn(cfg, mission, traj_params, payload)
% SIMULATE_GRAVITY_TURN — Integra a trajetória 2D por estágios.
% Entradas:
%   cfg.stages(i): Isp_s, thrust_N, fs_struct, mp_kg, CdA_m2
%   mission: target_alt [m], launch_lat [rad], etc.
%   traj_params: t_pitch [s], pitch_kick [rad], kick_dur [s]
%   payload: struct com massa (mass_kg) e volume (volume_m3)
% Saída:
%   traj: struct com histórico (t, r, theta, vr, vtheta, m, h, v, gamma)

env = earth_constants();
Re = env.Re; mu = env.mu; omega = env.omega;

% Empuxo inicial devido à rotação da Terra (componente Este)
v0_east = omega * Re * cos(mission.launch_lat);

% Mass stacking (início do estágio 1)
stages = cfg.stages;
N = numel(stages);

% calcular massas estruturais a partir de fs_struct e mp
for i=1:N
    fs = stages(i).fs_struct;
    mp = stages(i).mp_kg;
    ms = fs/(1-fs) * mp;     % m_struct = fs/(1-fs) * m_prop
    stages(i).ms_kg = ms;
end

m0 = payload.mass_kg + sum([stages.mp_kg]) + sum([stages.ms_kg]);

% Estado inicial
state = [Re; 0; 0; v0_east; m0];
t0 = 0;
t_hist = []; x_hist = [];

% Guidance
gpar.t_pitch = traj_params.t_pitch;
gpar.kick_dur = traj_params.kick_dur;
gpar.kick_ang = traj_params.pitch_kick;
ufun = guidance_profiles('vertical-then-kick-then-gravity-turn', gpar);

% Integração por estágios (queima completa de mp de cada estágio)
opts = odeset('RelTol',1e-7,'AbsTol',1e-8);

for i=1:N
    st = stages(i);
    mdot = st.thrust_N / (st.Isp_s * env.g0); % consumo de massa constante

    % Massa no fim da queima do estágio i (antes de separar estrutura)
    m_end_burn = state(5) - st.mp_kg;  % queima todo o propelente desse estágio

    % Tempo de queima
    tburn = st.mp_kg / mdot;

    % EDO com estágio atual
    eom = @(t, x) equations_of_motion(t, x, env, st, ufun);

    [t_seg, x_seg] = ode45(eom, [t0, t0+tburn], state, opts);

    % Forçar massa (último ponto = m_end_burn)
    x_seg(end,5) = m_end_burn;

    % Acumular histórico
    t_hist = [t_hist; t_seg];
    x_hist = [x_hist; x_seg];

    % Separação de estrutura do estágio i (drop ms) — se não for o último
    if i < N
        m_after_sep = m_end_burn - st.ms_kg;
    else
        m_after_sep = m_end_burn; % último estágio: mantém estrutura
    end

    % Atualizar estado para próximo estágio
    state = x_seg(end,:)';
    state(5) = m_after_sep;
    t0 = t_hist(end);
end

% Pós-Processamento
r  = x_hist(:,1);
vr = x_hist(:,3);
vtheta = x_hist(:,4);
m  = x_hist(:,5);

h = r - Re;
v = hypot(vr, vtheta);
gamma = atan2(vr, vtheta); % ângulo da trajetória [rad]

traj.t = t_hist;
traj.r = r;
traj.h = h;
traj.v = v;
traj.gamma = gamma;
traj.m = m;
traj.m0 = m0;
traj.cfg = cfg;
traj.traj_params = traj_params;
end
