function met = orbital_metrics(traj, mission)
%ORBITAL_METRICS Compare a trajectory with a target circular orbit.
%
% Required mission fields:
%   target_alt [m]
% Optional:
%   tol_v_ms   default 50 m/s
%   tol_gamma  default 2 deg

if ~isfield(mission,'target_alt')
    error('orbital_metrics:MissingTarget','mission.target_alt is required.');
end
if ~isfield(mission,'tol_v_ms'), mission.tol_v_ms=50; end
if ~isfield(mission,'tol_gamma'), mission.tol_gamma=deg2rad(2); end

env=earth_constants();
r_target=env.Re+mission.target_alt;
v_circ=sqrt(env.mu/r_target);

candidates=find(traj.h>=mission.target_alt);
if isempty(candidates)
    [~,idx]=max(traj.h);
    candidates=idx;
end

v_err_all=abs(traj.v(candidates)-v_circ);
g_err_all=abs(traj.gamma(candidates));
score=(v_err_all/max(mission.tol_v_ms,eps)).^2 + ...
      (g_err_all/max(mission.tol_gamma,eps)).^2;
[~,j]=min(score);
idx=candidates(j);

met.index=idx;
met.altitude_m=traj.h(idx);
met.velocity_ms=traj.v(idx);
met.gamma_rad=traj.gamma(idx);
met.circular_velocity_ms=v_circ;
met.velocity_error_ms=v_err_all(j);
met.gamma_error_rad=g_err_all(j);
met.reached=traj.h(idx)>=mission.target_alt && ...
    met.velocity_error_ms<=mission.tol_v_ms && ...
    met.gamma_error_rad<=mission.tol_gamma;
end
