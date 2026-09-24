function components = modern_stage_mer(stage, ms_kg, mp_kg)
%MODERN_STAGE_MER Explicit component policy for a candidate stage.
%
% This is a NEW aggregation policy informed by Chapter 4 of the 2014
% thesis, not a claim that the recovered prototype used this policy.
%
% Solids: motor casing + thrust structure + avionics + separate nozzle.
% Liquids: oxidizer and fuel tanks + thrust structure + avionics + engine.
% Hybrids: oxidizer tank + fuel-grain casing + thrust structure + avionics
%          + engine (hybrid casing coefficient is a modelling assumption).
%
% The engine MER depends on nozzle area ratio, so a separate nozzle MER is
% *not* added to liquid/hybrid engines by default (avoid double-counting).
% Fairing and insulation are included only with explicit geometry.
% This model does not yet estimate skin, interstages or dry-mass margin.
%
% The thesis coefficients use the H2-tank formula as a fallback for fuels
% other than RP1, and the LOX-tank formula for other oxidizers. Those
% generalizations have substantial uncertainty and require validation.

validateattributes(ms_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(mp_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'});
masses.mp_kg = mp_kg;
% Stage mass alone, not the upper stack, is used for avionics:
masses.m0_kg = ms_kg + mp_kg;
s.thrust_N = stage.thrust_N;
s.nozzle_area_ratio = stage.nozzle_area_ratio;
p.mixture_ratio_OF = stage.mixture_ratio_OF;
geometry = struct();
areas = {'fairing_area_m2','oxidizer_tank_area_m2','fuel_tank_area_m2'};
for i = 1:numel(areas)
    key = areas{i};
    if isfield(stage,key) && isfinite(stage.(key))
        geometry.(key) = stage.(key);
    end
end
mer = thesis_mer_components(s,masses,p,geometry);
components = struct('fuel_tank_kg',0,'oxidizer_tank_kg',0, ...
    'motor_casing_kg',0,'thrust_structure_kg',mer.thrust_structure_kg, ...
    'avionics_kg',mer.avionics_kg,'engine_kg',0,'nozzle_kg',0, ...
    'insulation_kg',0,'fairing_kg',0,'total_kg',0);

switch lower(stage.propulsion_type)
    case 'solid'
        components.motor_casing_kg = mer.motor_casing_kg;
        components.nozzle_kg = 125*(mp_kg/5400)^(2/3) * ...
            (stage.nozzle_area_ratio/10)^(1/4);
    case 'liquid'
        components.oxidizer_tank_kg = mer.lox_tank_formula_kg;
        if endsWith(upper(stage.propellant_name),'RP1')
            components.fuel_tank_kg = mer.rp1_tank_formula_kg;
        else
            components.fuel_tank_kg = mer.lh2_tank_formula_kg;
        end
        components.engine_kg = mer.engine_kg;
    case 'hybrid'
        components.oxidizer_tank_kg = mer.lox_tank_formula_kg;
        components.motor_casing_kg = 0.135*mer.fuel_kg;
        components.engine_kg = mer.engine_kg;
    otherwise
        error('modern_stage_mer:InvalidPropulsion','Unknown propulsion type.');
end

if isfinite(mer.fairing_kg)
    components.fairing_kg = mer.fairing_kg;
end
if isfinite(mer.lox_insulation_kg) && ...
        contains(upper(stage.propellant_name),'LOX')
    components.insulation_kg = components.insulation_kg + ...
        mer.lox_insulation_kg;
end
if isfinite(mer.lh2_insulation_kg) && ...
        contains(upper(stage.propellant_name),'H2')
    components.insulation_kg = components.insulation_kg + ...
        mer.lh2_insulation_kg;
end
fields = fieldnames(components);
total = 0;
for i = 1:numel(fields)
    if ~strcmp(fields{i},'total_kg')
        total = total + components.(fields{i});
    end
end
components.total_kg = total;
end
