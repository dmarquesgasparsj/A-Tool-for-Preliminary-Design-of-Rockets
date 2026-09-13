function cfg = validate_config(cfg)
%VALIDATE_CONFIG Validate and normalize a launcher configuration.
%   CFG = VALIDATE_CONFIG(CFG) checks the fields required by the current
%   trajectory model and computes structural masses when they are omitted.
%
%   Required per stage:
%     name, Isp_s, thrust_N, mp_kg, CdA_m2
%   And either:
%     fs_struct  OR  ms_kg
%
%   The function intentionally keeps the schema small. Future thesis-model
%   extensions (boosters, geometry, MER sizing, nozzle expansion, Cd(Mach))
%   should be added here so all configurations share one contract.

if ~isstruct(cfg) || ~isfield(cfg, 'stages') || isempty(cfg.stages)
    error('Configuration must contain a non-empty cfg.stages array.');
end

if ~isfield(cfg, 'name') || isempty(cfg.name)
    cfg.name = 'UNNAMED';
end

required = {'name','Isp_s','thrust_N','mp_kg','CdA_m2'};

for i = 1:numel(cfg.stages)
    st = cfg.stages(i);

    for k = 1:numel(required)
        field = required{k};
        if ~isfield(st, field)
            error('Stage %d is missing required field "%s".', i, field);
        end
    end

    validateattributes(st.Isp_s,     {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(st.thrust_N,  {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(st.mp_kg,     {'numeric'}, {'scalar','real','finite','nonnegative'});
    validateattributes(st.CdA_m2,    {'numeric'}, {'scalar','real','finite','nonnegative'});

    has_fs = isfield(st, 'fs_struct') && ~isempty(st.fs_struct);
    has_ms = isfield(st, 'ms_kg') && ~isempty(st.ms_kg);

    if ~has_fs && ~has_ms
        error('Stage %d must define either fs_struct or ms_kg.', i);
    end

    if has_fs
        validateattributes(st.fs_struct, {'numeric'}, ...
            {'scalar','real','finite','>=',0,'<',1});
        ms_from_fs = st.fs_struct/(1-st.fs_struct) * st.mp_kg;
        if has_ms
            validateattributes(st.ms_kg, {'numeric'}, ...
                {'scalar','real','finite','nonnegative'});
            rel_err = abs(st.ms_kg - ms_from_fs) / max(1, ms_from_fs);
            if rel_err > 1e-6
                warning('Stage %d: ms_kg and fs_struct are inconsistent; using ms_kg.', i);
            end
        else
            st.ms_kg = ms_from_fs;
        end
    else
        validateattributes(st.ms_kg, {'numeric'}, ...
            {'scalar','real','finite','nonnegative'});
        denom = st.ms_kg + st.mp_kg;
        if denom > 0
            st.fs_struct = st.ms_kg / denom;
        else
            st.fs_struct = 0;
        end
    end

    cfg.stages(i) = st;
end
end
