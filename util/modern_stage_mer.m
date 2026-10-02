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
% Optional Chapter-5 skin mass is enabled only when stage.include_skin_mass
% is true. Pressure-aware nozzle shell mass is also opt-in because the
% liquid/hybrid engine MER already contains an area-ratio term and adding
% a shell mass by default could double-count nozzle hardware.
% Optional fairing/interstage/adapter/wiring geometry and dry-mass margin are
% explicit modern components; the thesis had no interstage MER.
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
    'avionics_kg',mer.avionics_kg,'engine_kg',0,'engine_mass_detail',struct(), ...
    'nozzle_kg',0, ...
    'insulation_kg',0,'fairing_kg',0,'skin_kg',0, ...
    'pressure_nozzle_shell_kg',0,'secondary_structure_kg',0, ...
    'dry_mass_margin_kg',0,'total_kg',0);

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

% Optional 2026 engine-mass Future Work model. The historical MER remains
% the default, while a calibrated power law can include Pc, AR and O/F.
if any(strcmpi(stage.propulsion_type,{'liquid','hybrid'}))
    use_model=isfield(stage,'engine_mass_model') && ...
        isstruct(stage.engine_mass_model) && ~isempty(fieldnames(stage.engine_mass_model));
    if use_model
        enabled=true;
        if isfield(stage.engine_mass_model,'enabled')
            enabled=logical(stage.engine_mass_model.enabled);
        end
        if enabled
            detail=estimate_engine_mass(stage,stage.engine_mass_model);
            components.engine_kg=detail.mass_kg;
            components.engine_mass_detail=detail;
        end
    end
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

% Chapter 5 geometry / exterior structure (optional modern switch).
if isfield(stage,'include_skin_mass') && logical(stage.include_skin_mass)
    skin_opts=struct();
    if isfield(stage,'skin_model') && isstruct(stage.skin_model)
        skin_opts=stage.skin_model;
    end
    gskin=thesis_stage_geometry_skin(stage,mp_kg,skin_opts);
    components.skin_kg=gskin.skin_mass_kg;
    components.geometry=gskin;
end

% Optional fairing/interstage/payload-adapter/wiring geometry. The fairing
% may use thesis Eq. 4.16; other components require explicit user calibration.
secondary_fields={'fairing_model','interstage_model', ...
    'payload_adapter_model','wiring_model'};
has_secondary=false;
for jj=1:numel(secondary_fields)
    key=secondary_fields{jj};
    if isfield(stage,key) && isstruct(stage.(key)) && ...
            ~isempty(fieldnames(stage.(key)))
        has_secondary=true;
        break;
    end
end
if has_secondary
    sec=estimate_secondary_structure(stage);
    components.secondary_structure_kg=sec.total_kg;
    components.secondary_structure=sec;
    % Avoid double-counting fairing when a new fairing model is active and
    % legacy fairing_area_m2 was also supplied.
    if sec.fairing_kg>0 && components.fairing_kg>0
        components.fairing_kg=0;
    end
end

% Future Work extension: pressure-aware nozzle geometry/mass. For liquid
% and hybrid stages this shell is NOT added unless the caller explicitly
% requests add_pressure_nozzle_shell_mass=true, avoiding hidden double count.
if isfield(stage,'pressure_nozzle') && isstruct(stage.pressure_nozzle) && ...
        isfield(stage.pressure_nozzle,'enabled') && stage.pressure_nozzle.enabled
    pstage=stage;
    pn=fieldnames(stage.pressure_nozzle);
    for jj=1:numel(pn)
        if ~strcmp(pn{jj},'enabled')
            pstage.(pn{jj})=stage.pressure_nozzle.(pn{jj});
        end
    end
    nozzle_perf=pressure_aware_nozzle(pstage,0);
    components.pressure_nozzle=nozzle_perf;
    if isfinite(nozzle_perf.nozzle_shell_mass_kg)
        if strcmpi(stage.propulsion_type,'solid')
            components.nozzle_kg=nozzle_perf.nozzle_shell_mass_kg;
        elseif isfield(stage,'add_pressure_nozzle_shell_mass') && ...
                logical(stage.add_pressure_nozzle_shell_mass)
            components.pressure_nozzle_shell_kg=nozzle_perf.nozzle_shell_mass_kg;
        end
    end
end

% Optional dry-mass contingency applied to all modeled dry components before
% the margin itself. This is explicit rather than a hidden blanket factor.
base_total=0;
base_fields=fieldnames(components);
for jj=1:numel(base_fields)
    key=base_fields{jj};
    if ~any(strcmp(key,{'total_kg','dry_mass_margin_kg'})) && ...
            isnumeric(components.(key)) && isscalar(components.(key))
        base_total=base_total+components.(key);
    end
end
if isfield(stage,'dry_mass_margin_fraction') && ...
        isfinite(stage.dry_mass_margin_fraction) && ...
        stage.dry_mass_margin_fraction>0
    validateattributes(stage.dry_mass_margin_fraction,{'numeric'}, ...
        {'scalar','real','finite','>=',0,'<',1});
    components.dry_mass_margin_kg= ...
        stage.dry_mass_margin_fraction*base_total;
end

fields = fieldnames(components);
total = 0;
for i = 1:numel(fields)
    key=fields{i};
    if ~strcmp(key,'total_kg') && isnumeric(components.(key)) && ...
            isscalar(components.(key))
        total = total + components.(key);
    end
end
components.total_kg = total;
end
