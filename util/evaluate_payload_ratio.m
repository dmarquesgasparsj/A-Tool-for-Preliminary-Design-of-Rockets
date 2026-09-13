function [result, history] = evaluate_payload_ratio(cfg, mission, traj_bounds, opts)
%EVALUATE_PAYLOAD_RATIO Maximize payload while satisfying orbital conditions.
%   The current model optimizes three gravity-turn guidance parameters:
%     t_pitch, pitch_kick and kick_dur.
%   For each trajectory it finds the maximum feasible payload by bisection.
%
%   This remains a simplified trajectory-first model. The thesis-level
%   mass/configuration iteration will be layered above it in later steps.

if nargin < 4, opts = struct; end
if ~isfield(opts, 'verbose'), opts.verbose = false; end
if ~isfield(opts, 'grid_points'), opts.grid_points = [5 5 3]; end
if ~isfield(opts, 'payload_tol_kg'), opts.payload_tol_kg = 0.1; end
if ~isfield(opts, 'max_bisection_iter'), opts.max_bisection_iter = 30; end

cfg = validate_config(cfg);
validate_bounds(traj_bounds);

% Coarse search across the COMPLETE requested domain.
grid.t_pitch  = linspace(traj_bounds.t_pitch_s(1), ...
                         traj_bounds.t_pitch_s(2), opts.grid_points(1));
grid.kick_deg = linspace(traj_bounds.pitch_kick_deg(1), ...
                         traj_bounds.pitch_kick_deg(2), opts.grid_points(2));
grid.kick_dur = linspace(traj_bounds.kick_dur_s(1), ...
                         traj_bounds.kick_dur_s(2), opts.grid_points(3));

best.payload_kg = -Inf;
best.traj = [];
best.tp_params = struct();
eval_count = 0;

for tp = grid.t_pitch
    for kd = grid.kick_deg
        for kdurs = grid.kick_dur
            eval_count = eval_count + 1;
            tp_params = struct( ...
                't_pitch', tp, ...
                'pitch_kick', deg2rad(kd), ...
                'kick_dur', kdurs);

            [plmax, traj] = bisection_payload(cfg, mission, tp_params, opts);

            if opts.verbose
                fprintf('[grid %3d] t_pitch=%6.2fs | kick=%5.2fdeg | dur=%4.2fs => PL=%8.2f kg\n', ...
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

% Local refinement with fminsearch, but transformed variables guarantee
% that EVERY objective evaluation remains inside the physical bounds.
lb = [traj_bounds.t_pitch_s(1), ...
      deg2rad(traj_bounds.pitch_kick_deg(1)), ...
      traj_bounds.kick_dur_s(1)];
ub = [traj_bounds.t_pitch_s(2), ...
      deg2rad(traj_bounds.pitch_kick_deg(2)), ...
      traj_bounds.kick_dur_s(2)];
x0 = [best.tp_params.t_pitch, best.tp_params.pitch_kick, best.tp_params.kick_dur];
z0 = bounded_to_unconstrained(x0, lb, ub);

obj = @(z) -payload_for_traj(cfg, mission, vector_to_params( ...
    unconstrained_to_bounded(z, lb, ub)), opts);
zopt = fminsearch(obj, z0, optimset('Display','off'));
xopt = unconstrained_to_bounded(zopt, lb, ub);
tp_params2 = vector_to_params(xopt);
[plmax2, traj2] = bisection_payload(cfg, mission, tp_params2, opts);

if plmax2 > best.payload_kg
    best.payload_kg = plmax2;
    best.traj = traj2;
    best.tp_params = tp_params2;
end

result.payload_kg    = best.payload_kg;
result.m0_kg         = best.traj.m0;
result.payload_ratio = best.payload_kg / best.traj.m0;
result.traj          = best.tp_params;
result.orbit         = orbital_metrics(best.traj, mission);
result.config_name   = cfg.name;

history.best_traj = best.traj;
history.best_tp = best.tp_params;
history.grid_evaluations = eval_count;
end

function pl = payload_for_traj(cfg, mission, tp_params, opts)
[pl, ~] = bisection_payload(cfg, mission, tp_params, opts);
end

function [plmax, traj_best] = bisection_payload(cfg, mission, tp_params, opts)
% Find a valid upper bound first instead of assuming payload < 1/8 wet mass.
base_mass = sum([cfg.stages.mp_kg]) + sum([cfg.stages.ms_kg]);
pl_lo = 0;
pl_hi = max(100, 0.05 * base_mass);

traj0 = simulate_gravity_turn(cfg, mission, tp_params, 0);
if ~reaches_orbit(traj0, mission)
    plmax = 0;
    traj_best = traj0;
    return;
end
traj_best = traj0;

% Expand until the vehicle fails. This avoids silently clipping a capable
% launcher at an arbitrary payload fraction.
max_expand = 20;
for k = 1:max_expand
    traj_hi = simulate_gravity_turn(cfg, mission, tp_params, pl_hi);
    if ~reaches_orbit(traj_hi, mission)
        break;
    end
    pl_lo = pl_hi;
    traj_best = traj_hi;
    pl_hi = 2 * pl_hi;
end

traj_hi = simulate_gravity_turn(cfg, mission, tp_params, pl_hi);
if reaches_orbit(traj_hi, mission)
    warning('Payload upper bound remained feasible after %d expansions.', max_expand);
    plmax = pl_hi;
    traj_best = traj_hi;
    return;
end

for iter = 1:opts.max_bisection_iter
    if (pl_hi - pl_lo) <= opts.payload_tol_kg
        break;
    end

    pl_try = 0.5 * (pl_lo + pl_hi);
    traj = simulate_gravity_turn(cfg, mission, tp_params, pl_try);
    if reaches_orbit(traj, mission)
        pl_lo = pl_try;
        traj_best = traj;
    else
        pl_hi = pl_try;
    end
end
plmax = pl_lo;
end

function ok = reaches_orbit(traj, mission)
met = orbital_metrics(traj, mission);
ok = met.reached;
end

function met = orbital_metrics(traj, mission)
% Evaluate all samples at/above target altitude and choose the one closest
% to the requested circular-orbit conditions. Looking only at the FIRST
% altitude crossing can reject an otherwise feasible ascent trajectory.
env = earth_constants();
r_target = env.Re + mission.target_alt;
v_circ = sqrt(env.mu / r_target);

candidates = find(traj.h >= mission.target_alt);
if isempty(candidates)
    [~, idx] = max(traj.h);
    candidates = idx;
end

v_err_all = abs(traj.v(candidates) - v_circ);
g_err_all = abs(traj.gamma(candidates));
score = (v_err_all / max(mission.tol_v_ms, eps)).^2 + ...
        (g_err_all / max(mission.tol_gamma, eps)).^2;
[~, j] = min(score);
idx = candidates(j);

met.index = idx;
met.altitude_m = traj.h(idx);
met.velocity_ms = traj.v(idx);
met.gamma_rad = traj.gamma(idx);
met.circular_velocity_ms = v_circ;
met.velocity_error_ms = abs(traj.v(idx) - v_circ);
met.gamma_error_rad = abs(traj.gamma(idx));
met.reached = traj.h(idx) >= mission.target_alt && ...
              met.velocity_error_ms <= mission.tol_v_ms && ...
              met.gamma_error_rad <= mission.tol_gamma;
end

function params = vector_to_params(x)
params = struct('t_pitch', x(1), 'pitch_kick', x(2), 'kick_dur', x(3));
end

function z = bounded_to_unconstrained(x, lb, ub)
% Inverse logistic transform. Clamp normalized values away from 0/1.
y = (x - lb) ./ (ub - lb);
y = min(max(y, 1e-8), 1 - 1e-8);
z = log(y ./ (1 - y));
end

function x = unconstrained_to_bounded(z, lb, ub)
y = 1 ./ (1 + exp(-z));
x = lb + (ub - lb) .* y;
end

function validate_bounds(b)
fields = {'t_pitch_s','pitch_kick_deg','kick_dur_s'};
for i = 1:numel(fields)
    f = fields{i};
    if ~isfield(b, f) || numel(b.(f)) ~= 2 || ...
            ~all(isfinite(b.(f))) || b.(f)(2) <= b.(f)(1)
        error('traj_bounds.%s must be a finite [lower upper] pair.', f);
    end
end
end
