function air = atmosphere_relative_velocity_2d(r_m,vr_m_s,vtheta_m_s,env)
%ATMOSPHERE_RELATIVE_VELOCITY_2D Velocity relative to co-rotating atmosphere.
%
% The 2D ascent model keeps latitude fixed at the launch latitude. When
% env.atmosphere_rotates is true, local atmospheric tangential velocity is:
%   v_atm = omega * r * cos(launch_lat)
%
% Kinematics remain inertial; only aerodynamic speed/direction use the
% atmosphere-relative velocity.

if ~isfield(env,'launch_lat'), env.launch_lat=0; end
if ~isfield(env,'atmosphere_rotates'), env.atmosphere_rotates=true; end
vatm=0;
if logical(env.atmosphere_rotates)
    vatm=env.omega*r_m*cos(env.launch_lat);
end
air.vr_m_s=vr_m_s;
air.vtheta_m_s=vtheta_m_s-vatm;
air.speed_m_s=hypot(air.vr_m_s,air.vtheta_m_s);
air.atmosphere_tangential_speed_m_s=vatm;
end
