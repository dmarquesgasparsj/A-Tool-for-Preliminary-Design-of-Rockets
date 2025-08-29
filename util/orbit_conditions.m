function cond = orbit_conditions(orbit)
%ORBIT_CONDITIONS Compute target altitude and velocity for orbit insertion.
%   COND = ORBIT_CONDITIONS(ORBIT) returns a structure with fields:
%       altitude_m   - target altitude where velocity must match [m]
%       velocity_ms  - required orbital velocity at that altitude [m/s]
%       apoapsis_m   - desired apoapsis altitude [m] (only for elliptic)
%
%   ORBIT.type = 'circular' with field .altitude_km
%                'elliptic' with fields .periapsis_km and .apoapsis_km
%
%   Uses Earth constants from earth_constants().

env = earth_constants();

switch lower(orbit.type)
    case 'circular'
        cond.altitude_m = orbit.altitude_km * 1e3;
        r = env.Re + cond.altitude_m;
        cond.velocity_ms = sqrt(env.mu / r);
        cond.apoapsis_m = [];
    case {'elliptic','elliptical'}
        rp = env.Re + orbit.periapsis_km * 1e3;
        ra = env.Re + orbit.apoapsis_km * 1e3;
        a = 0.5 * (rp + ra);
        cond.altitude_m = orbit.periapsis_km * 1e3;
        cond.velocity_ms = sqrt(env.mu * (2/rp - 1/a));
        cond.apoapsis_m = orbit.apoapsis_km * 1e3;
    otherwise
        error('Unknown orbit type %s', orbit.type);
end
end

