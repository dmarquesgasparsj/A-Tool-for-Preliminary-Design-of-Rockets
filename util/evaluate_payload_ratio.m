function [result, history] = evaluate_payload_ratio(cfg, mission, traj_bounds, opts)
% Avalia payload ratio máximo por bisseção de carga útil e otimiza trajetória.
% 1) Otimiza t_pitch, pitch_kick e kick_dur para maximizar payload.
% 2) Dentro de cada avaliação, encontra por bisseção a m_PL máxima que atinge a órbita.

if nargin < 4, opts = struct; end
if ~isfield(opts, 'verbose'), opts.verbose = false; end

% Busca inicial grosseira na trajetória (grid)
grid.t_pitch   = linspace(traj_bounds.t_pitch_s(1), traj_bounds.t_pitch_s(1), 5);
grid.kick_deg  = linspace(traj_bounds.pitch_kick_deg(1), traj_bounds.pitch_kick_deg(1), 5);
grid.kick_dur  = linspace(traj_bounds.kick_dur_s(1), traj_bounds.kick_dur_s(1), 3);

best.payload_kg = -Inf; best.traj = struct();
eval_count = 0;

for tp = grid.t_pitch
  for kd = grid.kick_deg
    for kdurs = grid.kick_dur
        eval_count = eval_count + 1;
        tp_params.t_pitch    = tp;
        tp_params.pitch_kick = deg2rad(kd);
        tp_params.kick_dur   = kdurs;

        % Bisseção em massa de payload
        [plmax, traj] = bisection_payload(cfg, mission, tp_params);

        if opts.verbose
            fprintf('[grid %3d] t_pitch=%.1fs | kick=%.1fdeg | dur=%.1fs  =>  PL=%.1f kg\n', ...
                eval_count, tp, kd, kdurs, plmax);
        end

        if plmax > best.payload_kg
            best.payload_kg = plmax;
            best.traj = traj;
            best.tp_params = tp_params;
        end
    end
  end
end

% Refinamento local com fminsearch em torno do melhor (sem toolboxes)
x0 = [best.tp_params.t_pitch, best.tp_params.pitch_kick, best.tp_params.kick_dur];
obj = @(x) - payload_for_traj(cfg, mission, struct('t_pitch', x(1), 'pitch_kick', x(2), 'kick_dur', x(3)));
xopt = fminsearch(obj, x0, optimset('Display','off'));

tp_params2.t_pitch    = max(traj_bounds.t_pitch_s(1), min(traj_bounds.t_pitch_s(2), xopt(1)));
tp_params2.pitch_kick = max(deg2rad(traj_bounds.pitch_kick_deg(1)), min(deg2rad(traj_bounds.pitch_kick_deg(2)), xopt(2)));
tp_params2.kick_dur   = max(traj_bounds.kick_dur_s(1), min(traj_bounds.kick_dur_s(2), xopt(3)));

[plmax2, traj2] = bisection_payload(cfg, mission, tp_params2);

if plmax2 > best.payload_kg
    best.payload_kg = plmax2;
    best.traj = traj2;
    best.tp_params = tp_params2;
end

% Resultado final
m0 = best.traj.m0;
result.payload_kg   = best.payload_kg;
result.m0_kg        = m0;
result.payload_ratio= best.payload_kg / m0;
result.traj         = best.tp_params;

% Histórico simples
history.best_traj   = best.traj;
history.best_tp     = best.tp_params;
end

function pl = payload_for_traj(cfg, mission, tp_params)
[pl, ~] = bisection_payload(cfg, mission, tp_params);
end

function [plmax, traj_best] = bisection_payload(cfg, mission, tp_params)
% Procura máxima carga útil por bisseção de massa.
% Define limites: 0 kg até um limite superior heurístico (1/8 da massa total húmida)
% Itera simulando e verificando se a condição orbital é satisfeita.

% Estimativa grosseira de m0 sem payload
m0_wo_pl = sum([cfg.stages.mp_kg]) + sum(arrayfun(@(s) s.fs_struct/(1-s.fs_struct)*s.mp_kg, cfg.stages));
pl_hi = max(100.0, 0.125 * m0_wo_pl);  % limite superior heurístico
pl_lo = 0.0;

traj_best = [];
for iter=1:20
    pl_try = 0.5*(pl_lo + pl_hi);
    traj = simulate_gravity_turn(cfg, mission, tp_params, pl_try);
    if reaches_orbit(traj, mission)
        pl_lo = pl_try; traj_best = traj;
    else
        pl_hi = pl_try;
    end
end
plmax = pl_lo;
if isempty(traj_best)
    traj_best = simulate_gravity_turn(cfg, mission, tp_params, plmax);
end
end

function ok = reaches_orbit(traj, mission)
% Verifica critério de órbita: altitude >= target_alt, velocidade ~ v_circ e gamma ~ 0
env = earth_constants();
r_target = env.Re + mission.target_alt;
v_circ   = sqrt(env.mu / r_target);

% encontrar o instante em que h cruza target_alt (ou o ponto mais alto)
idx = find(traj.h >= mission.target_alt, 1, 'first');
if isempty(idx)
    [~, idx] = max(traj.h);
end

v_err = abs(traj.v(idx) - v_circ);
g_err = abs(traj.gamma(idx));
ok = (traj.h(idx) >= mission.target_alt) && (v_err <= mission.tol_v_ms) && (g_err <= mission.tol_gamma);
end
