function sol = thesis_legacy_mer_solve_stage(stage, payload_above_kg, ...
        delta_v_ms, n_stages, stage_index, opts, context)
%THESIS_LEGACY_MER_SOLVE_STAGE Find epsilon consistent with surviving MER code.
%
% The 2014 scripts sweep epsilon = 0.05:0.01:0.17 and compare the
% Tsiolkovsky structural mass against a version-specific MER sum.
% Here the same equations and range are used, but bisection replaces
% the coarse grid to reach the thesis 0.1% structural-mass agreement.
% Bisection and defensive checks are modern numerical maintenance.
%
% This routine is opt-in. It does not model solids or add geometry,
% boosters, gravity/drag losses or the exo-atmospheric trajectory.

if nargin < 6, opts = struct(); end
if nargin < 7, context = struct(); end
if ~isfield(opts,'g0'), opts.g0 = 9.80665; end
if ~isfield(opts,'epsilon_bounds'), opts.epsilon_bounds = [0.05 0.17]; end
if ~isfield(opts,'mer_rel_tol'), opts.mer_rel_tol = 1e-3; end
if ~isfield(opts,'max_mer_iterations'), opts.max_mer_iterations = 100; end
if ~isfield(opts,'mer_options'), opts.mer_options = struct(); end
validateattributes(opts.epsilon_bounds,{'numeric'}, ...
    {'vector','numel',2,'real','finite'});
if any(opts.epsilon_bounds <= 0) || ...
        opts.epsilon_bounds(2) <= opts.epsilon_bounds(1)
    error('thesis_legacy_mer_solve_stage:InvalidBounds', ...
        'epsilon_bounds must contain two increasing positive values.');
end
validateattributes(opts.mer_rel_tol,{'numeric'}, ...
    {'scalar','positive','finite'});
if ~isfield(stage,'epsilon0'), stage.epsilon0 = 0.10; end

k = exp(delta_v_ms/(opts.g0*stage.Isp_s));
low = opts.epsilon_bounds(1);
high = min(opts.epsilon_bounds(2),(1-1e-8)/k);
if low >= high
    error('thesis_legacy_mer_solve_stage:Infeasible', ...
        'No physically feasible epsilon in the requested range.');
end

% A scan detects a bracket even if the component sum is not monotone.
grid_eps = linspace(low,high,129);
grid_f = nan(size(grid_eps));
for j = 1:numel(grid_eps)
    grid_f(j) = mass_residual(grid_eps(j));
end
brackets = find(isfinite(grid_f(1:end-1)) & ...
    isfinite(grid_f(2:end)) & ...
    grid_f(1:end-1).*grid_f(2:end) <= 0);
if isempty(brackets)
    error('thesis_legacy_mer_solve_stage:NoConsistentFactor', ...
        ['No structural-factor/MER agreement in [%.3f, %.3f]. ', ...
         'Check stage inputs and the historical liquid-MER assumptions.'], ...
        low, high);
end
centres = (grid_eps(brackets)+grid_eps(brackets+1))/2;
[~,best] = min(abs(centres-stage.epsilon0));
j = brackets(best);
a = grid_eps(j); b = grid_eps(j+1);
fa = grid_f(j);
epsilon = (a+b)/2;
for iter = 1:opts.max_mer_iterations
    epsilon = (a+b)/2;
    fmid = mass_residual(epsilon);
    if abs(fmid) <= opts.mer_rel_tol*max(1, ...
            structural_mass(epsilon))
        break;
    end
    if fa*fmid <= 0
        b = epsilon;
    else
        a = epsilon;
        fa = fmid;
    end
end
[ms,mp,k] = thesis_stage_mass(payload_above_kg,delta_v_ms, ...
    stage.Isp_s,epsilon,opts.g0);
masses = make_masses(ms,mp);
mer = thesis_legacy_mer(stage,masses,n_stages,stage_index,opts.mer_options);
rel_residual = abs(ms-mer.total_kg)/max(1,ms);
if rel_residual > opts.mer_rel_tol
    error('thesis_legacy_mer_solve_stage:NoConvergence', ...
        'MER residual %.5g exceeds requested relative tolerance.',rel_residual);
end
sol.ms_kg = ms;
sol.mp_kg = mp;
sol.k = k;
sol.epsilon = epsilon;
sol.mer = mer;
sol.mer_relative_residual = rel_residual;
sol.iterations = iter;
sol.epsilon_bounds = [low high];
sol.method = 'scan + bisection (modern solver of recovered 2014 equations)';

    function f = mass_residual(eps_candidate)
        [ms0,mp0] = thesis_stage_mass(payload_above_kg, ...
            delta_v_ms,stage.Isp_s,eps_candidate,opts.g0);
        m0 = make_masses(ms0,mp0);
        estimate = thesis_legacy_mer(stage,m0, ...
            n_stages,stage_index,opts.mer_options);
        f = ms0-estimate.total_kg;
    end

    function ms0 = structural_mass(eps_candidate)
        ms0 = thesis_stage_mass(payload_above_kg,delta_v_ms, ...
            stage.Isp_s,eps_candidate,opts.g0);
    end

    function m = make_masses(ms0,mp0)
        m.mp_kg = mp0;
        m.payload_above_kg = payload_above_kg;
        m.section_initial_mass_kg = payload_above_kg+ms0+mp0;
        if isfield(context,'upper_next_kg')
            m.upper_next_kg = context.upper_next_kg;
        end
    end
end
