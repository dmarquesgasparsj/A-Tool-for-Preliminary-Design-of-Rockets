function m_engine_kg = estimate_engine_mass(thrust_N)
% ESTIMATE_ENGINE_MASS  Heurística simples para massa do motor [kg].
%   Assume relação empuxo/peso típica de 50.
%   thrust_N  - empuxo do motor [N]
%   m_engine_kg - massa estimada [kg]

T_W = 50;           % relação empuxo/peso típica
g0 = 9.80665;       % gravidade ao nível do mar [m/s^2]
m_engine_kg = thrust_N / (T_W * g0);
end

function volume_m3 = estimate_tank_volume(propellant_mass_kg, density_kgm3)
% ESTIMATE_TANK_VOLUME  Volume aproximado do tanque [m^3].
%   propellant_mass_kg - massa de propelente [kg]
%   density_kgm3       - densidade do propelente [kg/m^3]

volume_m3 = propellant_mass_kg / density_kgm3;
end
