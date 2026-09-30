function out = interplanetary_transfer_analysis(target_orbit_radius_AU,parking_altitude_m,opts)
%INTERPLANETARY_TRANSFER_ANALYSIS Hohmann + patched-conic Earth departure.
%
% This is a preliminary coplanar circular-orbit mission estimate.
% target_orbit_radius_AU may be inside or outside Earth's orbit.
%
% Outputs:
%   heliocentric Hohmann Delta-V at Earth and target distance
%   Earth-relative departure hyperbolic excess v_inf
%   characteristic energy C3 = v_inf^2
%   injection Delta-V from a circular Earth parking orbit
%   Hohmann coast time
%
% opts.target_body_circular_speed_m_s may override the target circular
% heliocentric speed if a non-Solar central model is desired.

if nargin<3 || isempty(opts), opts=struct(); end
validateattributes(target_orbit_radius_AU,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(parking_altitude_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
env=earth_constants();
rE=env.AU_m;
rT=target_orbit_radius_AU*env.AU_m;
helio=hohmann_transfer(env.mu_sun,rE,rT);

vEarth=sqrt(env.mu_sun/rE);
vTarget=sqrt(env.mu_sun/rT);
vInfDepart=abs(helio.v_transfer_1_m_s-vEarth);
vInfArrive=abs(vTarget-helio.v_transfer_2_m_s);
C3=vInfDepart^2;

rp=env.Re+parking_altitude_m;
vCirc=sqrt(env.mu/rp);
vEscHyp=sqrt(vInfDepart^2+2*env.mu/rp);
dvInject=vEscHyp-vCirc;

out.target_orbit_radius_AU=target_orbit_radius_AU;
out.parking_altitude_m=parking_altitude_m;
out.heliocentric_transfer=helio;
out.departure_v_inf_m_s=vInfDepart;
out.arrival_v_inf_m_s=vInfArrive;
out.C3_m2_s2=C3;
out.C3_km2_s2=C3/1e6;
out.earth_parking_circular_speed_m_s=vCirc;
out.earth_departure_perigee_speed_m_s=vEscHyp;
out.earth_injection_delta_v_m_s=dvInject;
out.heliocentric_departure_delta_v_m_s=abs(helio.delta_v1_m_s);
out.heliocentric_arrival_delta_v_m_s=abs(helio.delta_v2_m_s);
out.transfer_time_s=helio.time_of_flight_s;
out.transfer_time_days=helio.time_of_flight_s/86400;
out.model_status=['2026 preliminary patched-conic mission estimate using ', ...
    'coplanar circular heliocentric Hohmann transfer.'];
end
