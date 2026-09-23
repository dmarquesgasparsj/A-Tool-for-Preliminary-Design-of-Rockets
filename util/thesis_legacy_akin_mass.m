function mer = thesis_legacy_akin_mass(mp_kg, stage_wet_reference_kg, thrust_N, OF, nozzle_area_ratio)
%THESIS_LEGACY_AKIN_MASS Recover the MER aggregation used in the 2014 code.
%
% This function mirrors the aggregation visible in the recovered four-stage
% MATLAB source from the thesis project. It intentionally preserves the
% original assumptions rather than silently replacing them with newer ones.
%
% Inputs
%   mp_kg                  propellant mass [kg]
%   stage_wet_reference_kg mass used by the original avionics MER [kg]
%   thrust_N               stage thrust [N]
%   OF                     oxidizer/fuel mixture ratio
%   nozzle_area_ratio      nozzle expansion/area ratio used by the legacy code
%
% Output
%   mer                     component masses and total heuristic structural mass
%
% Historical note:
% The original code labels the split propellants as H2 and LOX and applies
% the H2/LOX tank MER coefficients using only OF, even when the propellant
% menu allowed other combinations. This behaviour is preserved here because
% this module is a recovery of the 2014 implementation, not a new model.

arguments
    mp_kg (1,1) double {mustBeNonnegative}
    stage_wet_reference_kg (1,1) double {mustBePositive}
    thrust_N (1,1) double {mustBeNonnegative}
    OF (1,1) double {mustBePositive}
    nozzle_area_ratio (1,1) double {mustBePositive}
end

m_oxidizer = OF * mp_kg / (OF + 1);
m_fuel = mp_kg / (OF + 1);

mer.fuel_kg = m_fuel;
mer.oxidizer_kg = m_oxidizer;

% Akin MERs used directly in the recovered source.
mer.fuel_tank_kg = 0.128 * m_fuel;
mer.oxidizer_tank_kg = 0.0107 * m_oxidizer;
mer.avionics_kg = 10 * stage_wet_reference_kg^0.361;
mer.nozzle_kg = 125 * (mp_kg / 5400)^(2/3) * (nozzle_area_ratio / 10)^(1/4);
mer.engine_kg = 7.81e-4 * thrust_N + ...
    3.37e-5 * thrust_N * sqrt(nozzle_area_ratio) + 59;
mer.thrust_structure_kg = 2.55e-4 * thrust_N;

mer.total_kg = mer.fuel_tank_kg + mer.oxidizer_tank_kg + ...
    mer.avionics_kg + mer.nozzle_kg + mer.engine_kg + ...
    mer.thrust_structure_kg;
end
