function result = thesis_modern_stage_mass(payload_above_kg, delta_v_ms, stage, opts)
%THESIS_MODERN_STAGE_MASS Continuous MER/epsilon consistency solver.
%
% Finds epsilon such that the Tsiolkovsky structural mass agrees with the
% selected component MER sum. Uses bounded bisection (no toolboxes).
% Unlike the recovered development code, it neither rounds masses nor
% silently chooses the last point in an arbitrary epsilon grid.
%
% The solver rejects infeasible designs and returns a numerical residual.
% Not a substitute for geometry, aerodynamic or trajectory validation.

if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts,'g0'), opts.g0 = 9.80665; end
if ~isfield(opts,'epsilon_max'), opts.epsilon_max = 0.5; end
if ~isfield(opts,'relative_mass_tolerance')
    opts.relative_mass_tolerance = 1e-5;
end
if ~isfield(opts,'epsilon_tolerance')
    opts.epsilon_tolerance = 1e-12;
end
if ~isfield(opts,'max_iterations'), opts.max_iterations = 100; end

validateattributes(payload_above_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'payload_above_kg');
validateattributes(delta_v_ms,{'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'delta_v_ms');
validateattributes(opts.g0,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(opts.epsilon_max,{'numeric'}, ...
    {'scalar','real','finite','positive','<',1});
validateattributes(opts.relative_mass_tolerance,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(opts.epsilon_tolerance,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(opts.max_iterations,{'numeric'}, ...
    {'scalar','integer','positive'});

if ~isfield(stage,'Isp_s') || ~isfield(stage,'thrust_N')
    error('thesis_modern_stage_mass:MissingField', ...
        'Stage needs Isp_s and thrust_N.');
end
validateattributes(stage.Isp_s,{'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'Isp_s');

k = exp(delta_v_ms / (stage.Isp_s * opts.g0));
if ~isfinite(k)
    error('thesis_modern_stage_mass:InfeasibleStage', ...
        'Delta-V exceeds the finite stage-sizing domain.');
end
upper = min(opts.epsilon_max, (1 - 1e-8)/k);
if upper <= 0
    error('thesis_modern_stage_mass:NoStructuralRoot', ...
        'No feasible structural-factor interval.');
end
lower = 0;
[f_lower,~,~,~] = evaluate(lower);
[f_upper,~,~,~] = evaluate(upper);
if ~(f_lower < 0 && f_upper > 0)
    error('thesis_modern_stage_mass:NoStructuralRoot', ...
        ['No MER-consistent structural factor in (0, %.6g). ', ...
         'Change the stage design or epsilon_max.'],upper);
end

for iteration = 1:opts.max_iterations
    midpoint = 0.5*(lower+upper);
    [residual,ms,mp,mer] = evaluate(midpoint);
    relative_residual = abs(residual) / max(ms,mer.total_kg);

    if relative_residual <= opts.relative_mass_tolerance
        result = struct();
        result.epsilon = midpoint;
        result.k = k;
        result.ms_kg = ms;
        result.mp_kg = mp;
        result.stage_wet_mass_kg = ms + mp;
        result.section_initial_mass_kg = payload_above_kg + ms + mp;
        result.structural_residual_kg = residual;
        result.relative_mass_residual = relative_residual;
        result.iterations = iteration;
        result.mdot_kg_s = stage.thrust_N / (stage.Isp_s*opts.g0);
        result.burn_time_s = mp / result.mdot_kg_s;
        result.mer = mer;
        return
    end
    if residual > 0
        upper = midpoint;
    else
        lower = midpoint;
    end
    if upper-lower < opts.epsilon_tolerance
        break
    end
end
error('thesis_modern_stage_mass:Nonconvergence', ...
    'MER sizing did not meet the requested relative mass tolerance.');

    function [residual,ms,mp,mer] = evaluate(epsilon)
        [ms,mp] = thesis_stage_mass(payload_above_kg,delta_v_ms, ...
            stage.Isp_s,epsilon,opts.g0);
        mer = thesis_modern_mer_components(stage,mp,payload_above_kg+ms+mp);
        residual = ms - mer.total_kg;
    end
end
