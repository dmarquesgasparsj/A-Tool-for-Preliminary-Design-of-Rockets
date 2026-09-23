function result = thesis_mass_model(cfg, payload_kg, total_delta_v_ms, opts)
%THESIS_MASS_MODEL Reconstructed 2014 multistage mass model.
%
% RESULT = THESIS_MASS_MODEL(CFG, PAYLOAD_KG, DELTAV_MS) uses fixed
% structural factors, preserving the API introduced in the first
% reconstruction.
%
% RESULT = THESIS_MASS_MODEL(..., OPTS), with
% OPTS.structural_model = 'legacy_mer', enables the MER aggregation
% recovered from the surviving 2014 mass_model_n_{2,3,4}.m files and
% solves for structural factor within the historical 0.05--0.17 range.
%
% Required stage fields in all modes: name, Isp_s, delta_v_fraction,
% epsilon0. 'legacy_mer' additionally needs thrust_N and
% mixture_ratio_OF; nozzle_area_ratio can be supplied or uses the
% stage-dependent value recovered from the historical scripts.
%
% IMPORTANT: the surviving sources use LOX/H2 tank MERs irrespective of
% selected propellant. Explicitly marked solid stages are refused in
% legacy_mer mode. Do not use these liquid approximations to claim that
% Vega or other solid-propellant validation has been reproduced.
% No trajectory coupling or boosters are included in this function.

if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts,'structural_model')
    opts.structural_model = 'fixed';
end
use_mer = strcmpi(opts.structural_model,'legacy_mer');
if ~use_mer && ~strcmpi(opts.structural_model,'fixed')
    error('thesis_mass_model:UnknownStructuralModel', ...
        'structural_model must be fixed or legacy_mer.');
end
if ~isfield(opts,'g0')
    if use_mer
        opts.g0 = 9.81; % Surviving 2014 scripts
    else
        opts.g0 = 9.80665;
    end
end
if ~isfield(opts,'fraction_tolerance')
    opts.fraction_tolerance = 1e-10;
end
validateattributes(payload_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'},mfilename,'payload_kg');
validateattributes(total_delta_v_ms,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'},mfilename,'total_delta_v_ms');

if ~isstruct(cfg) || ~isfield(cfg,'stages') || isempty(cfg.stages)
    error('thesis_mass_model:InvalidConfig', ...
        'cfg.stages must be a non-empty struct array.');
end
stages = cfg.stages;
N = numel(stages);
fractions = zeros(1,N);
required = {'name','Isp_s','delta_v_fraction','epsilon0'};
for i = 1:N
    for j = 1:numel(required)
        if ~isfield(stages(i),required{j})
            error('thesis_mass_model:MissingField', ...
                'Stage %d is missing field "%s".',i,required{j});
        end
    end
    validateattributes(stages(i).delta_v_fraction,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    fractions(i) = stages(i).delta_v_fraction;
end
if abs(sum(fractions)-1)>opts.fraction_tolerance
    error('thesis_mass_model:DeltaVFractions', ...
        'Stage delta_v_fraction values must sum to 1.');
end
if use_mer && (N < 2 || N > 4)
    error('thesis_mass_model:LegacyStageCount', ...
        'Surviving MER policies only cover 2, 3 or 4 stages.');
end

out = repmat(struct( ...
    'name','', ...
    'payload_above_kg',0, ...
    'delta_v_ms',0, ...
    'Isp_s',0, ...
    'epsilon',0, ...
    'k',0, ...
    'ms_kg',0, ...
    'mp_kg',0, ...
    'stage_wet_mass_kg',0, ...
    'section_initial_mass_kg',0, ...
    'mer_structural_mass_kg',NaN, ...
    'mer_relative_residual',NaN, ...
    'mer_iterations',0, ...
    'mer_components',struct(), ...
    'thrust_N',NaN, ...
    'burn_time_s',NaN),1,N);

payload_above = payload_kg;
for i = N:-1:1
    st = stages(i);
    dv = total_delta_v_ms*st.delta_v_fraction;
    if use_mer
        context = struct();
        if i < N
            context.upper_next_kg = out(i+1).payload_above_kg;
        end
        sol = thesis_legacy_mer_solve_stage(st, ...
            payload_above,dv,N,i,opts,context);
        ms = sol.ms_kg;
        mp = sol.mp_kg;
        k = sol.k;
        epsilon = sol.epsilon;
        out(i).mer_structural_mass_kg = sol.mer.total_kg;
        out(i).mer_relative_residual = sol.mer_relative_residual;
        out(i).mer_iterations = sol.iterations;
        out(i).mer_components = sol.mer;
    else
        epsilon = st.epsilon0;
        [ms,mp,k] = thesis_stage_mass(payload_above,dv, ...
            st.Isp_s,epsilon,opts.g0);
    end

    out(i).name = st.name;
    out(i).payload_above_kg = payload_above;
    out(i).delta_v_ms = dv;
    out(i).Isp_s = st.Isp_s;
    out(i).epsilon = epsilon;
    out(i).k = k;
    out(i).ms_kg = ms;
    out(i).mp_kg = mp;
    out(i).stage_wet_mass_kg = ms+mp;
    out(i).section_initial_mass_kg = payload_above+ms+mp;
    if isfield(st,'thrust_N') && st.thrust_N>0
        out(i).thrust_N = st.thrust_N;
        out(i).burn_time_s = mp*opts.g0*st.Isp_s/st.thrust_N;
    end
    payload_above = payload_above+ms+mp;
end
result.payload_kg = payload_kg;
result.total_delta_v_ms = total_delta_v_ms;
result.stages = out;
result.GLOW_kg = payload_above;
result.payload_ratio = payload_kg/payload_above;
result.delta_v_fractions = fractions;
result.structural_model = opts.structural_model;
if use_mer
    result.reconstruction_status = [ ...
        'Original 2014 version-specific MER sums recovered; ', ...
        '0.1% structural consistency solved by modern bisection. ', ...
        'Liquid tank assumption only; no trajectory coupling or solids.'];
else
    result.reconstruction_status = [ ...
        '2014 stage-sizing equations and upper-to-lower stacking ', ...
        'with caller-supplied fixed structural factors.'];
end
end
