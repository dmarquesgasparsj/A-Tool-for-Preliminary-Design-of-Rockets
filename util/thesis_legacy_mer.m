function mer = thesis_legacy_mer(stage, masses, n_stages, stage_index, options)
%THESIS_LEGACY_MER Recover MER aggregation from the surviving 2014 source.
%
% The recovered mass_model_n_{2,3,4}.m files use different component
% combinations. Reproduce the version selected by N_STAGES instead of
% claiming that one aggregation rule existed for all launcher types.
%
% All masses are kg, thrust N and nozzle area ratio dimensionless.
% MASSES: mp_kg, section_initial_mass_kg, payload_above_kg;
%         upper_next_kg is required only for the literal 3-stage bug.
%
% The original experimental code uses LOX/H2 tank estimates for EVERY
% O/F selection, even solids. This function refuses explicitly marked
% solid stages: a physically valid solid-motor policy is still missing.
%
% Options.n3_first_stage_avionics:
%   'corrected' (default) = stage wet mass (2026 correction);
%   'verbatim' = LOW - M_2 - M_3 (literal surviving source).

if nargin < 5, options = struct(); end
if ~isfield(options,'n3_first_stage_avionics')
    options.n3_first_stage_avionics = 'corrected';
end
validateattributes(n_stages,{'numeric'},{'scalar','integer','>=',2,'<=',4});
validateattributes(stage_index,{'numeric'}, ...
    {'scalar','integer','>=',1,'<=',n_stages});
if isfield(stage,'propellant_kind') && ...
        strcmpi(stage.propellant_kind,'solid')
    error('thesis_legacy_mer:UnsupportedSolidPropellant', ...
        ['The original LOX/H2 tank sum cannot describe a solid stage. ', ...
         'A separate solid casing policy must be validated first.']);
end
required_stage = {'thrust_N','mixture_ratio_OF'};
for j = 1:numel(required_stage)
    if ~isfield(stage,required_stage{j})
        error('thesis_legacy_mer:MissingField', ...
            'Stage is missing %s.',required_stage{j});
    end
end
required_masses = {'mp_kg','section_initial_mass_kg','payload_above_kg'};
for j = 1:numel(required_masses)
    if ~isfield(masses,required_masses{j})
        error('thesis_legacy_mer:MissingField', ...
            'Masses is missing %s.',required_masses{j});
    end
end
validateattributes(stage.thrust_N,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(stage.mixture_ratio_OF,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(masses.mp_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(masses.section_initial_mass_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(masses.payload_above_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
if isfield(stage,'nozzle_area_ratio') && ~isempty(stage.nozzle_area_ratio)
    area_ratio = stage.nozzle_area_ratio;
else
    defaults = { [30 20], [100 100 100], [20 30 60 100] };
    area_ratio = defaults{n_stages-1}(stage_index);
end
validateattributes(area_ratio,{'numeric'}, ...
    {'scalar','real','finite','positive'});

stage_mer.thrust_N = stage.thrust_N;
stage_mer.nozzle_area_ratio = area_ratio;
masses_mer.mp_kg = masses.mp_kg;
masses_mer.m0_kg = masses.section_initial_mass_kg;
propellant.mixture_ratio_OF = stage.mixture_ratio_OF;
components = thesis_mer_components(stage_mer,masses_mer,propellant);

wet_kg = masses.section_initial_mass_kg - masses.payload_above_kg;
switch n_stages
    case 2
        if stage_index == 1
            tank_factor = 3;
            thrust_structure_factor = 1.55e-4;
            engine_factor = 1;
        else
            tank_factor = 1;
            thrust_structure_factor = 2.55e-4;
            engine_factor = 0.2;
        end
        include_nozzle = false;
        avionics_base_kg = masses.section_initial_mass_kg;
    case 3
        tank_factor = 1;
        thrust_structure_factor = 2.55e-4;
        engine_factor = 0;
        include_nozzle = true;
        if stage_index == 3
            avionics_base_kg = masses.section_initial_mass_kg;
        elseif stage_index == 2
            avionics_base_kg = wet_kg;
        elseif strcmpi(options.n3_first_stage_avionics,'verbatim')
            if ~isfield(masses,'upper_next_kg')
                error('thesis_legacy_mer:MissingField', ...
                    'Verbatim 3-stage first-stage rule needs upper_next_kg.');
            end
            % mass_model_n_3.m line 226: LOW-M_2-M_3.
            % This subtracts M_3 twice because M_2 already contains it.
            avionics_base_kg = wet_kg - masses.upper_next_kg;
        elseif strcmpi(options.n3_first_stage_avionics,'corrected')
            avionics_base_kg = wet_kg;
        else
            error('thesis_legacy_mer:InvalidOption', ...
                'n3_first_stage_avionics must be corrected or verbatim.');
        end
    case 4
        tank_factor = 1;
        thrust_structure_factor = 2.55e-4;
        engine_factor = 1;
        include_nozzle = true;
        if stage_index == 3
            avionics_base_kg = wet_kg;
        else
            avionics_base_kg = masses.section_initial_mass_kg;
        end
end
if ~isfinite(avionics_base_kg) || avionics_base_kg <= 0
    error('thesis_legacy_mer:InvalidAvionicsMass', ...
        ['The historical avionics-mass expression is nonpositive; ', ...
         'see docs/RECOVERED_2014_SOURCE.md.']);
end

mer.components = components;
mer.tank_kg = tank_factor * ...
    (components.lox_tank_formula_kg + components.lh2_tank_formula_kg);
mer.avionics_kg = 10*avionics_base_kg^0.361;
mer.engine_kg = engine_factor*components.engine_kg;
mer.thrust_structure_kg = thrust_structure_factor*stage.thrust_N;
mer.nozzle_kg = 0;
if include_nozzle
    mer.nozzle_kg = 125*(masses.mp_kg/5400)^(2/3)* ...
        (area_ratio/10)^(1/4);
end
mer.total_kg = mer.tank_kg + mer.avionics_kg + ...
    mer.engine_kg + mer.thrust_structure_kg + mer.nozzle_kg;
mer.source_variant = sprintf('mass_model_n_%d.m',n_stages);
mer.nozzle_area_ratio = area_ratio;
mer.avionics_reference_mass_kg = avionics_base_kg;
mer.uses_legacy_liquid_assumption = true;
mer.n3_avionics_mode = options.n3_first_stage_avionics;
end
