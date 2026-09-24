function result = thesis_modern_mass_model(cfg, payload_kg, total_delta_v_ms, opts)
%THESIS_MODERN_MASS_MODEL MER-coupled serial-stage sizing (2026 improvement).
%
% A clean, no-GUI, no-global-variables implementation of the original
% upper-stage-to-lower-stage sizing architecture. The component selection
% and continuous numerical epsilon solution are modern improvements.
%
% Required per-stage fields:
% name, Isp_s, thrust_N, delta_v_fraction, nozzle_area_ratio,
% propellant_kind; liquid stages also need mixture_ratio_OF.
% Boosters and the coupled orbital trajectory are NOT yet implemented.
%
% Example: result = thesis_modern_mass_model(modern_demo_config(),1500,5500)

if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts,'g0'), opts.g0 = 9.80665; end
if ~isfield(opts,'fraction_tolerance'), opts.fraction_tolerance = 1e-8; end
if ~isfield(opts,'min_liftoff_TWR'), opts.min_liftoff_TWR = 1.2; end
if ~isfield(opts,'require_liftoff_TWR'), opts.require_liftoff_TWR = false; end

validateattributes(payload_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'payload_kg');
validateattributes(total_delta_v_ms,{'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'total_delta_v_ms');

if ~isstruct(cfg) || ~isfield(cfg,'stages') || ...
        ~isstruct(cfg.stages) || isempty(cfg.stages)
    error('thesis_modern_mass_model:InvalidConfig', ...
        'cfg.stages must be a non-empty struct array.');
end
if isfield(cfg,'boosters') && ~isempty(cfg.boosters)
    error('thesis_modern_mass_model:UnsupportedBoosters', ...
        'This mass model handles only serial stages; boosters need a separate model.');
end

stages = cfg.stages;
n = numel(stages);
fractions = zeros(1,n);
for i = 1:n
    required = {'name','Isp_s','thrust_N','delta_v_fraction', ...
        'nozzle_area_ratio','propellant_kind'};
    for j = 1:numel(required)
        if ~isfield(stages(i),required{j})
            error('thesis_modern_mass_model:MissingField', ...
                'Stage %d missing %s.',i,required{j});
        end
    end
    validateattributes(stages(i).delta_v_fraction,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    fractions(i) = stages(i).delta_v_fraction;
end
if abs(sum(fractions)-1) > opts.fraction_tolerance
    error('thesis_modern_mass_model:DeltaVFractions', ...
        'The serial-stage Delta-V fractions must sum to 1.');
end

template = struct('name','','Isp_s',0,'thrust_N',0, ...
    'propellant_kind','','delta_v_fraction',0,'delta_v_ms',0, ...
    'payload_above_kg',0,'epsilon',0,'k',0, ...
    'ms_kg',0,'mp_kg',0,'stage_wet_mass_kg',0, ...
    'section_initial_mass_kg',0,'structural_residual_kg',0, ...
    'relative_mass_residual',0,'iterations',0, ...
    'mdot_kg_s',0,'burn_time_s',0,'mer',struct());
out = repmat(template,1,n);
payload_above = payload_kg;

for i = n:-1:1
    st = stages(i);
    dv = total_delta_v_ms*fractions(i);
    solved = thesis_modern_stage_mass(payload_above,dv,st,opts);

    out(i).name = char(st.name);
    out(i).Isp_s = st.Isp_s;
    out(i).thrust_N = st.thrust_N;
    out(i).propellant_kind = char(st.propellant_kind);
    out(i).delta_v_fraction = fractions(i);
    out(i).delta_v_ms = dv;
    out(i).payload_above_kg = payload_above;

    fields = fieldnames(solved);
    for j = 1:numel(fields)
        out(i).(fields{j}) = solved.(fields{j});
    end
    payload_above = solved.section_initial_mass_kg;
end

result.payload_kg = payload_kg;
result.total_delta_v_ms = total_delta_v_ms;
result.stages = out;
result.GLOW_kg = payload_above;
result.payload_ratio = payload_kg/payload_above;
result.delta_v_fractions = fractions;
result.liftoff_TWR = stages(1).thrust_N/(payload_above*opts.g0);
result.min_liftoff_TWR = opts.min_liftoff_TWR;
result.liftoff_TWR_ok = result.liftoff_TWR >= opts.min_liftoff_TWR;
result.model_status = ['2026 improved serial-stage mass sizing. ', ...
    'Trajectory, parallel boosters and full GLOW validation not included.'];

if opts.require_liftoff_TWR && ~result.liftoff_TWR_ok
    error('thesis_modern_mass_model:InsufficientLiftoffTWR', ...
        'Liftoff T/W %.3f is below the required %.3f.', ...
        result.liftoff_TWR,opts.min_liftoff_TWR);
end
end
