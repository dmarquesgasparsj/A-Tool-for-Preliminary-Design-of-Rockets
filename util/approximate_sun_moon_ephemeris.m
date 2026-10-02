function eph = approximate_sun_moon_ephemeris(t_s,opts)
%APPROXIMATE_SUN_MOON_EPHEMERIS Low-order Earth-centred Sun/Moon positions.
%
% This built-in ephemeris is for sensitivity studies and regression tests,
% not precision mission design. It uses circular mean orbits. For high
% fidelity, pass an external ephemeris function to propagate_orbit_3d.
%
% Constants: JPL DE440 GM values and IAU astronomical unit; lunar mean
% distance/period are consistent with NASA Moon fact-sheet values.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'sun_phase_rad'), opts.sun_phase_rad=0; end
if ~isfield(opts,'moon_phase_rad'), opts.moon_phase_rad=0; end
if ~isfield(opts,'moon_inclination_deg'), opts.moon_inclination_deg=28.58; end
validateattributes(t_s,{'numeric'},{'scalar','real','finite'});

day=86400;
au=149597870700;
year=365.25636*day;
moon_a=384400e3;
moon_period=27.3217*day;
obliq=deg2rad(23.439281);
moon_inc=deg2rad(opts.moon_inclination_deg);

ths=opts.sun_phase_rad+2*pi*t_s/year;
r_ecl=[au*cos(ths);au*sin(ths);0];
Rx=[1 0 0;0 cos(obliq) -sin(obliq);0 sin(obliq) cos(obliq)];
sun=Rx*r_ecl;

thm=opts.moon_phase_rad+2*pi*t_s/moon_period;
moon=[moon_a*cos(thm); ...
    moon_a*sin(thm)*cos(moon_inc); ...
    moon_a*sin(thm)*sin(moon_inc)];

eph.sun_position_eci_m=sun;
eph.moon_position_eci_m=moon;
eph.mu_sun_m3_s2=1.32712440041279419e20;
eph.mu_moon_m3_s2=4902.800118e9;
eph.model_status=['Circular mean-orbit ephemeris for preliminary ', ...
    'third-body sensitivity only; use JPL/Horizons state vectors for precision.'];
end
