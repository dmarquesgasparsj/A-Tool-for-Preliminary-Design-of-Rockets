function result = thesis_mass_model(cfg, payload_kg, total_delta_v_ms, opts)
%THESIS_MASS_MODEL Reconstruct the unambiguous 2014 multistage sizing core.
%
%   RESULT = THESIS_MASS_MODEL(CFG, PAYLOAD_KG, TOTAL_DELTAV_MS)
%   sizes the launcher from the upper stage downward using the stage mass
%   equations documented in section 5.3.1 of the 2014 thesis.
%
%   Required stage fields:
%       name
%       Isp_s
%       delta_v_fraction
%       epsilon0          initial/current structural factor
%
%   The payload of a stage is the mass of everything above it. Therefore
%   the calculation proceeds N -> 1, exactly as described in the thesis.
%
%   This first restoration intentionally does NOT invent the undocumented
%   aggregation rule used by the original source code to combine all MER
%   component estimates into a new structural mass. MER equations are
%   restored separately in thesis_mer_components.m and will be coupled once
%   the historical aggregation logic can be supported by evidence.

if nargin < 4, opts = struct(); end
if ~isfield(opts, 'g0'), opts.g0 = 9.80665; end
if ~isfield(opts, 'fraction_tolerance'), opts.fraction_tolerance = 1e-10; end

validateattributes(payload_kg, {'numeric'}, ...
    {'scalar','real','finite','nonnegative'}, mfilename, 'payload_kg');
validateattributes(total_delta_v_ms, {'numeric'}, ...
    {'scalar','real','finite','nonnegative'}, mfilename, 'total_delta_v_ms');

if ~isstruct(cfg) || ~isfield(cfg, 'stages') || isempty(cfg.stages)
    error('thesis_mass_model:InvalidConfig', ...
        'cfg.stages must be a non-empty struct array.');
end

stages = cfg.stages;
N = numel(stages);
fractions = zeros(1, N);

required = {'name','Isp_s','delta_v_fraction','epsilon0'};
for i = 1:N
    for j = 1:numel(required)
        if ~isfield(stages(i), required{j})
            error('thesis_mass_model:MissingField', ...
                'Stage %d is missing field "%s".', i, required{j});
        end
    end
    validateattributes(stages(i).delta_v_fraction, {'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    fractions(i) = stages(i).delta_v_fraction;
end

if abs(sum(fractions) - 1) > opts.fraction_tolerance
    error('thesis_mass_model:DeltaVFractions', ...
        'Stage delta_v_fraction values must sum to 1.');
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
    'section_initial_mass_kg',0), 1, N);

payload_above = payload_kg;

% Thesis: design starts with the last stage and proceeds downward.
for i = N:-1:1
    st = stages(i);
    dv = total_delta_v_ms * st.delta_v_fraction;

    [ms, mp, k] = thesis_stage_mass(payload_above, dv, ...
        st.Isp_s, st.epsilon0, opts.g0);

    out(i).name = st.name;
    out(i).payload_above_kg = payload_above;
    out(i).delta_v_ms = dv;
    out(i).Isp_s = st.Isp_s;
    out(i).epsilon = st.epsilon0;
    out(i).k = k;
    out(i).ms_kg = ms;
    out(i).mp_kg = mp;
    out(i).stage_wet_mass_kg = ms + mp;
    out(i).section_initial_mass_kg = payload_above + ms + mp;

    payload_above = payload_above + ms + mp;
end

result.payload_kg = payload_kg;
result.total_delta_v_ms = total_delta_v_ms;
result.stages = out;
result.GLOW_kg = payload_above;
result.payload_ratio = payload_kg / payload_above;
result.delta_v_fractions = fractions;
result.reconstruction_status = [ ...
    '2014 stage-sizing equations and upper-to-lower stacking restored; ', ...
    'MER structural-factor iteration not yet coupled.'];
end
