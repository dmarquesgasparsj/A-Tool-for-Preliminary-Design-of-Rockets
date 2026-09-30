function out = geo_transfer_analysis(parking_altitude_m,opts)
%GEO_TRANSFER_ANALYSIS LEO/parking-orbit to GEO preliminary transfer.
%
% opts.initial_inclination_deg  default 0
% opts.final_inclination_deg    default 0
% opts.combine_plane_change_at_apogee default true
% opts.Isp_s                    optional, for propellant mass ratio
%
% GEO radius is computed from Earth rotation and mu rather than hard-coded.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'initial_inclination_deg'), opts.initial_inclination_deg=0; end
if ~isfield(opts,'final_inclination_deg'), opts.final_inclination_deg=0; end
if ~isfield(opts,'combine_plane_change_at_apogee')
    opts.combine_plane_change_at_apogee=true;
end
validateattributes(parking_altitude_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
env=earth_constants();
r1=env.Re+parking_altitude_m;
r2=env.geo_radius_m;
base=hohmann_transfer(env.mu,r1,r2);
di=deg2rad(abs(opts.final_inclination_deg-opts.initial_inclination_deg));

dv1=abs(base.delta_v1_m_s);
if logical(opts.combine_plane_change_at_apogee) && di>0
    % Combine circularization and plane change by vector subtraction.
    dv2=sqrt(base.v_transfer_2_m_s^2+base.v_circular_2_m_s^2- ...
        2*base.v_transfer_2_m_s*base.v_circular_2_m_s*cos(di));
    plane_strategy='combined with GEO circularization at apogee';
else
    dv2=abs(base.delta_v2_m_s);
    dvplane=2*base.v_circular_2_m_s*sin(di/2);
    dv2=dv2+dvplane;
    plane_strategy='separate circular-GEO plane change';
end

out.hohmann=base;
out.parking_altitude_m=parking_altitude_m;
out.geo_radius_m=r2;
out.geo_altitude_m=r2-env.Re;
out.inclination_change_deg=rad2deg(di);
out.delta_v_departure_m_s=dv1;
out.delta_v_apogee_m_s=dv2;
out.total_delta_v_m_s=dv1+dv2;
out.transfer_time_s=base.time_of_flight_s;
out.transfer_time_h=base.time_of_flight_s/3600;
out.plane_change_strategy=plane_strategy;
if isfield(opts,'Isp_s') && ~isempty(opts.Isp_s)
    validateattributes(opts.Isp_s,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    out.final_to_initial_mass_ratio= ...
        exp(-out.total_delta_v_m_s/(opts.Isp_s*env.g0));
    out.propellant_fraction=1-out.final_to_initial_mass_ratio;
else
    out.final_to_initial_mass_ratio=NaN;
    out.propellant_fraction=NaN;
end
out.model_status=['2026 mission-layer GEO estimate: circular parking orbit, ', ...
    'two-impulse Hohmann transfer and optional apogee plane change.'];
end
