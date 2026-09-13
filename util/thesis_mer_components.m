function mer = thesis_mer_components(stage, masses, propellant, geometry)
%THESIS_MER_COMPONENTS Mass Estimation Relationships documented in 2014.
%
% This function restores the component-level MER equations stated in
% section 4.4 of the thesis. It deliberately returns the component values
% separately rather than silently choosing how to sum them, because the
% thesis does not fully document the original source-code aggregation rule.
%
% Required stage fields:
%   thrust_N, nozzle_area_ratio
%
% Required masses fields:
%   mp_kg, m0_kg
%
% PROPellant may contain:
%   mixture_ratio_OF, fuel, oxidizer
%
% GEOMETRY is optional and may contain:
%   fairing_area_m2, oxidizer_tank_area_m2, fuel_tank_area_m2

if nargin < 4, geometry = struct(); end
if nargin < 3 || isempty(propellant), propellant = struct(); end

required_stage = {'thrust_N','nozzle_area_ratio'};
for i = 1:numel(required_stage)
    if ~isfield(stage, required_stage{i})
        error('thesis_mer_components:MissingStageField', ...
            'Missing stage field "%s".', required_stage{i});
    end
end
if ~isfield(masses, 'mp_kg') || ~isfield(masses, 'm0_kg')
    error('thesis_mer_components:MissingMassField', ...
        'masses must contain mp_kg and m0_kg.');
end

T = stage.thrust_N;
Ar = stage.nozzle_area_ratio;
mp = masses.mp_kg;
m0 = masses.m0_kg;

validateattributes(T, {'numeric'}, {'scalar','real','finite','nonnegative'});
validateattributes(Ar, {'numeric'}, {'scalar','real','finite','nonnegative'});
validateattributes(mp, {'numeric'}, {'scalar','real','finite','nonnegative'});
validateattributes(m0, {'numeric'}, {'scalar','real','finite','nonnegative'});

% Equations (4.5)-(4.7)
mer.thrust_structure_kg = 2.55e-4 * T;
mer.motor_casing_kg = 0.135 * mp;
mer.engine_kg = 7.81e-4 * T + 3.37e-5 * T * sqrt(Ar) + 59;

% Equation (4.17)
mer.avionics_kg = 10 * m0^0.361;

% Propellant split from equations (2.19)-(2.20), when OF is known.
mer.oxidizer_kg = NaN;
mer.fuel_kg = NaN;
if isfield(propellant, 'mixture_ratio_OF') && ...
        ~isempty(propellant.mixture_ratio_OF) && ...
        isfinite(propellant.mixture_ratio_OF)
    OF = propellant.mixture_ratio_OF;
    validateattributes(OF, {'numeric'}, {'scalar','real','finite','positive'});
    mer.oxidizer_kg = OF * mp / (OF + 1);
    mer.fuel_kg = mp / (OF + 1);
end

% Equations (4.8)-(4.10). These fields are named after the equations in
% the thesis. Whether a particular launcher should use each relationship
% belongs to the higher-level reconstruction policy, not this function.
if isfinite(mer.oxidizer_kg)
    mer.lox_tank_formula_kg = 0.0107 * mer.oxidizer_kg;
else
    mer.lox_tank_formula_kg = NaN;
end
if isfinite(mer.fuel_kg)
    mer.lh2_tank_formula_kg = 0.128 * mer.fuel_kg;
    mer.rp1_tank_formula_kg = 0.0148 * mer.fuel_kg;
else
    mer.lh2_tank_formula_kg = NaN;
    mer.rp1_tank_formula_kg = NaN;
end

% Equations (4.11)-(4.12), only when the relevant areas are known.
mer.lox_insulation_kg = NaN;
mer.lh2_insulation_kg = NaN;
if isfield(geometry, 'oxidizer_tank_area_m2')
    mer.lox_insulation_kg = 1.123 * geometry.oxidizer_tank_area_m2;
end
if isfield(geometry, 'fuel_tank_area_m2')
    mer.lh2_insulation_kg = 2.88 * geometry.fuel_tank_area_m2;
end

% Equation (4.16), last-stage/fairing use only when area is supplied.
mer.fairing_kg = NaN;
if isfield(geometry, 'fairing_area_m2')
    mer.fairing_kg = 4.95 * geometry.fairing_area_m2^1.15;
end

mer.source = 'Gaspar MSc thesis (2014), section 4.4';
mer.note = ['Component equations restored verbatim; no undocumented ', ...
    'component aggregation is assumed here.'];
end
