function C = earth_constants()
%EARTH_CONSTANTS Earth constants used across the modern trajectory models.
%
% Re and GM follow the values already used by the project. J2 is added for
% optional non-spherical-Earth propagation; historical 2014 paths keep J2
% disabled unless explicitly requested.

C.Re    = 6378137.0;          % [m] equatorial radius
C.mu    = 3.986004418e14;     % [m^3/s^2] Earth gravitational parameter
C.g0    = 9.80665;            % [m/s^2] standard gravity
C.omega = 7.2921159e-5;       % [rad/s] Earth rotation
C.J2    = 1.08263e-3;         % [-] Earth second zonal harmonic

% Mission-analysis constants for heliocentric transfer estimates.
C.AU_m  = 149597870700;       % [m] astronomical unit (IAU exact)
C.mu_sun = 1.32712440018e20;  % [m^3/s^2]
C.geo_radius_m = (C.mu/C.omega^2)^(1/3);
end
