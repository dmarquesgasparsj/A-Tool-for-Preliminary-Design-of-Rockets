function init = launch_initial_conditions(mission,mass_kg)
%LAUNCH_INITIAL_CONDITIONS Generalized ground / inclined / air-launch state.
%
% The historical 2014 default remains a ground launch with zero vehicle-
% relative speed and a 90 deg flight-path angle. Modern missions may set:
%   initial_altitude_m
%   initial_speed_m_s
%   initial_flight_path_angle_deg (or _rad), measured above local horizontal
%   initial_downrange_angle_rad
%   include_earth_rotation (default true)
%   launch_lat              radians, matching the existing trajectory API
%
% initial_speed_m_s is relative to the rotating Earth/atmosphere. The local
% eastward rotation speed is added separately when enabled.

if nargin<2
    error('launch_initial_conditions:Mass','mass_kg is required.');
end
validateattributes(mass_kg,{'numeric'},{'scalar','real','finite','positive'});
if ~isfield(mission,'launch_lat'), mission.launch_lat=0; end
if ~isfield(mission,'initial_altitude_m'), mission.initial_altitude_m=0; end
if ~isfield(mission,'initial_speed_m_s'), mission.initial_speed_m_s=0; end
if ~isfield(mission,'initial_downrange_angle_rad')
    mission.initial_downrange_angle_rad=0;
end
if ~isfield(mission,'include_earth_rotation')
    mission.include_earth_rotation=true;
end

if isfield(mission,'initial_flight_path_angle_rad')
    gamma=mission.initial_flight_path_angle_rad;
elseif isfield(mission,'initial_flight_path_angle_deg')
    gamma=deg2rad(mission.initial_flight_path_angle_deg);
else
    gamma=pi/2;
end
validateattributes(mission.launch_lat,{'numeric'}, ...
    {'scalar','real','finite','>=',-pi/2,'<=',pi/2});
validateattributes(mission.initial_altitude_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(mission.initial_speed_m_s,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(gamma,{'numeric'}, ...
    {'scalar','real','finite','>=',-pi/2,'<=',pi/2});

env=earth_constants();
r0=env.Re+mission.initial_altitude_m;
vrel=mission.initial_speed_m_s;
vr=vrel*sin(gamma);
vtheta=vrel*cos(gamma);
vrotation=0;
if logical(mission.include_earth_rotation)
    vrotation=env.omega*r0*cos(mission.launch_lat);
    vtheta=vtheta+vrotation;
end

init.state=[r0;mission.initial_downrange_angle_rad;vr;vtheta;mass_kg];
init.radius_m=r0;
init.altitude_m=mission.initial_altitude_m;
init.relative_speed_m_s=vrel;
init.flight_path_angle_rad=gamma;
init.flight_path_angle_deg=rad2deg(gamma);
init.rotation_speed_m_s=vrotation;
init.inertial_tangential_speed_m_s=vtheta;
init.radial_speed_m_s=vr;
init.mass_kg=mass_kg;
init.is_historical_ground_default= ...
    mission.initial_altitude_m==0 && mission.initial_speed_m_s==0 && ...
    abs(gamma-pi/2)<1e-12;
if init.is_historical_ground_default
    init.mode='ground_vertical';
elseif mission.initial_altitude_m>0 || mission.initial_speed_m_s>0
    init.mode='air_or_moving_launch';
else
    init.mode='inclined_ground_launch';
end
end
