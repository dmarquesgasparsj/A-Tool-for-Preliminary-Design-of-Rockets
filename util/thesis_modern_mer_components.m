function mer = thesis_modern_mer_components(stage, mp_kg, section_initial_mass_kg)
%THESIS_MODERN_MER_COMPONENTS Propellant-aware MER accounting (2026).
% Scientific basis: component MERs documented in Gaspar (2014).
% Modern correction: do not apply LOX/LH2 tank formulae to every propellant.
%
% stage.propellant_kind: 'solid', 'LOX/LH2', 'LOX/RP1', or 'custom-liquid'.
% Custom liquids MUST supply oxidizer_tank_mass_fraction and
% fuel_tank_mass_fraction: no undocumented coefficients are assumed.
% Tank insulation and fairing are included only when their areas are given.
%
% This is a preliminary estimate, not an engine design or verified launcher.

required = {'thrust_N','nozzle_area_ratio','propellant_kind'};
for i = 1:numel(required)
    if ~isfield(stage,required{i})
        error('thesis_modern_mer_components:MissingField', ...
            'Missing stage field: %s.',required{i});
    end
end

validateattributes(stage.thrust_N, {'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'thrust_N');
validateattributes(stage.nozzle_area_ratio, {'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'nozzle_area_ratio');
validateattributes(mp_kg, {'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'mp_kg');
validateattributes(section_initial_mass_kg, {'numeric'}, ...
    {'scalar','real','finite','positive'},mfilename,'section_initial_mass_kg');

kind = lower(strtrim(char(stage.propellant_kind)));
mer = struct('fuel_kg',0,'oxidizer_kg',0, ...
    'fuel_tank_kg',0,'oxidizer_tank_kg',0,'motor_casing_kg',0, ...
    'engine_kg',0,'nozzle_kg',0,'thrust_structure_kg',0, ...
    'avionics_kg',0,'fuel_insulation_kg',0, ...
    'oxidizer_insulation_kg',0,'fairing_kg',0, ...
    'extra_kg',0,'total_kg',0);

switch kind
    case 'solid'
        % Equation (4.6): solid motor casing, with no liquid engine or tanks.
        mer.motor_casing_kg = 0.135 * mp_kg;
    case {'lox/lh2','lox/rp1','custom-liquid'}
        if ~isfield(stage,'mixture_ratio_OF')
            error('thesis_modern_mer_components:MissingOF', ...
                'Liquid stages require mixture_ratio_OF.');
        end
        OF = stage.mixture_ratio_OF;
        validateattributes(OF,{'numeric'}, ...
            {'scalar','real','finite','positive'},mfilename,'mixture_ratio_OF');
        mer.oxidizer_kg = mp_kg * OF / (OF + 1);
        mer.fuel_kg = mp_kg / (OF + 1);

        switch kind
            case 'lox/lh2'
                oxidizer_fraction = 0.0107;
                fuel_fraction = 0.128;
            case 'lox/rp1'
                oxidizer_fraction = 0.0107;
                fuel_fraction = 0.0148;
            otherwise
                if ~isfield(stage,'oxidizer_tank_mass_fraction') || ...
                        ~isfield(stage,'fuel_tank_mass_fraction')
                    error('thesis_modern_mer_components:MissingTankMER', ...
                        'Custom liquids must specify both tank mass fractions.');
                end
                oxidizer_fraction = stage.oxidizer_tank_mass_fraction;
                fuel_fraction = stage.fuel_tank_mass_fraction;
                validateattributes(oxidizer_fraction,{'numeric'}, ...
                    {'scalar','real','finite','nonnegative'});
                validateattributes(fuel_fraction,{'numeric'}, ...
                    {'scalar','real','finite','nonnegative'});
        end

        mer.oxidizer_tank_kg = oxidizer_fraction * mer.oxidizer_kg;
        mer.fuel_tank_kg = fuel_fraction * mer.fuel_kg;
        mer.engine_kg = 7.81e-4 * stage.thrust_N + ...
            3.37e-5 * stage.thrust_N * ...
            sqrt(stage.nozzle_area_ratio) + 59;
    otherwise
        error('thesis_modern_mer_components:UnknownPropellant', ...
            'Unsupported propellant_kind: %s.',kind);
end

% Equations (4.5), (4.17), and the nozzle MER in the recovered source.
mer.thrust_structure_kg = 2.55e-4 * stage.thrust_N;
mer.avionics_kg = 10 * section_initial_mass_kg^0.361;
mer.nozzle_kg = 125 * (mp_kg/5400)^(2/3) * ...
    (stage.nozzle_area_ratio/10)^(1/4);

% Optional known geometry; never invent the corresponding areas.
if isfield(stage,'oxidizer_tank_area_m2') && ...
        ~isempty(stage.oxidizer_tank_area_m2)
    if strcmp(kind,'solid')
        error('thesis_modern_mer_components:SolidTankArea', ...
            'A solid motor cannot have a liquid oxidizer tank.');
    end
    validateattributes(stage.oxidizer_tank_area_m2,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    mer.oxidizer_insulation_kg = 1.123 * stage.oxidizer_tank_area_m2;
end
if isfield(stage,'fuel_tank_area_m2') && ...
        ~isempty(stage.fuel_tank_area_m2)
    if strcmp(kind,'solid')
        error('thesis_modern_mer_components:SolidTankArea', ...
            'A solid motor cannot have a liquid fuel tank.');
    end
    validateattributes(stage.fuel_tank_area_m2,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    mer.fuel_insulation_kg = 2.88 * stage.fuel_tank_area_m2;
end
if isfield(stage,'fairing_area_m2') && ~isempty(stage.fairing_area_m2)
    validateattributes(stage.fairing_area_m2,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    mer.fairing_kg = 4.95 * stage.fairing_area_m2^1.15;
end
if isfield(stage,'extra_structural_mass_kg') && ...
        ~isempty(stage.extra_structural_mass_kg)
    validateattributes(stage.extra_structural_mass_kg,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    mer.extra_kg = stage.extra_structural_mass_kg;
end

components = {'fuel_tank_kg','oxidizer_tank_kg','motor_casing_kg', ...
    'engine_kg','nozzle_kg','thrust_structure_kg','avionics_kg', ...
    'fuel_insulation_kg','oxidizer_insulation_kg','fairing_kg','extra_kg'};
for i = 1:numel(components)
    mer.total_kg = mer.total_kg + mer.(components{i});
end
mer.model = 'Modern propellant-aware preliminary MER (2026)';
end
