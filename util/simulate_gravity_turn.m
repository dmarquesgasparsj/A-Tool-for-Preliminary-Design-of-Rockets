function traj = simulate_gravity_turn(cfg, mission, traj_params, payload_mass)
%SIMULATE_GRAVITY_TURN Integrate a simplified 2D staged ascent.
%   The vehicle flies vertically, performs a short pitch kick and then
%   follows a gravity turn with thrust aligned to the velocity vector.
%
%   This function deliberately contains only the trajectory propagation.
%   Vehicle sizing belongs to the mass/design model, so pre-computed ms_kg
%   values are respected instead of being silently overwritten here.

cfg = validate_config(cfg);
validateattributes(payload_mass, {'numeric'}, ...
    {'scalar','real','finite','nonnegative'});

required_mission = {'target_alt','launch_lat'};
for k = 1:numel(required_mission)
    if ~isfield(mission, required_mission{k})
        error('Mission is missing required field "%s".', required_mission{k});
    end
end

required_guidance = {'t_pitch','pitch_kick','kick_dur'};
for k = 1:numel(required_guidance)
    if ~isfield(traj_params, required_guidance{k})
        error('Trajectory parameters are missing "%s".', required_guidance{k});
    end
end

env = earth_constants();
Re = env.Re;
omega = env.omega;

% Initial eastward velocity from Earth's rotation.
v0_east = omega * Re * cos(mission.launch_lat);

stages = cfg.stages;
N = numel(stages);
m0 = payload_mass + sum([stages.mp_kg]) + sum([stages.ms_kg]);

% State = [radius; longitude-like angle; radial velocity; tangential velocity; mass]
state = [Re; 0; 0; v0_east; m0];
t0 = 0;
t_hist = [];
x_hist = [];
stage_index_hist = [];
stage_events = repmat(struct('name','','t_start',0,'t_burnout',0, ...
    'mass_start_kg',0,'mass_burnout_kg',0,'mass_after_sep_kg',0), 1, N);

% Guidance profile.
gpar.t_pitch = traj_params.t_pitch;
gpar.kick_dur = traj_params.kick_dur;
gpar.kick_ang = traj_params.pitch_kick;
ufun = guidance_profiles('vertical-then-kick-then-gravity-turn', gpar);

ode_opts = odeset('RelTol',1e-7,'AbsTol',1e-8);

for i = 1:N
    st = stages(i);
    mdot = st.thrust_N / (st.Isp_s * env.g0);
    tburn = st.mp_kg / mdot;
    m_start = state(5);
    m_end_burn = m_start - st.mp_kg;

    eom = @(t, x) equations_of_motion(t, x, env, st, ufun);
    [t_seg, x_seg] = ode45(eom, [t0, t0 + tburn], state, ode_opts);

    % Numerical integration of mass is theoretically identical to the
    % analytical burn value. Pin the final sample to prevent drift.
    x_seg(end,5) = m_end_burn;

    % Avoid duplicate boundary sample when concatenating stages.
    if i > 1
        t_seg = t_seg(2:end);
        x_seg = x_seg(2:end,:);
    end

    t_hist = [t_hist; t_seg]; %#ok<AGROW>
    x_hist = [x_hist; x_seg]; %#ok<AGROW>
    stage_index_hist = [stage_index_hist; repmat(i, numel(t_seg), 1)]; %#ok<AGROW>

    if i < N
        m_after_sep = m_end_burn - st.ms_kg;
    else
        m_after_sep = m_end_burn;
    end

    stage_events(i).name = st.name;
    stage_events(i).t_start = t0;
    stage_events(i).t_burnout = t0 + tburn;
    stage_events(i).mass_start_kg = m_start;
    stage_events(i).mass_burnout_kg = m_end_burn;
    stage_events(i).mass_after_sep_kg = m_after_sep;

    state = x_seg(end,:)';
    state(5) = m_after_sep;
    t0 = t0 + tburn;
end

r = x_hist(:,1);
vr = x_hist(:,3);
vtheta = x_hist(:,4);
h = r - Re;
v = hypot(vr, vtheta);
gamma = atan2(vr, vtheta);

traj.t = t_hist;
traj.r = r;
traj.theta = x_hist(:,2);
traj.vr = vr;
traj.vtheta = vtheta;
traj.h = h;
traj.v = v;
traj.gamma = gamma;
traj.m = x_hist(:,5);
traj.m0 = m0;
traj.payload_kg = payload_mass;
traj.stage_index = stage_index_hist;
traj.stage_events = stage_events;
traj.cfg = cfg;
% Post-process first-order ascent losses. These diagnostics are used by the
% modern mass/trajectory coupling loop. They are not a replacement for the
% thesis TPBVP free-flight phase.
rho_hist=zeros(size(t_hist));
q_hist=zeros(size(t_hist));
cd_hist=zeros(size(t_hist));
mach_hist=zeros(size(t_hist));
drag_hist=zeros(size(t_hist));
drag_rate=zeros(size(t_hist));
gravity_rate=zeros(size(t_hist));

kn_length=NaN;
kn_threshold=5;
if isfield(cfg,'knudsen_characteristic_length_m')
    kn_length=cfg.knudsen_characteristic_length_m;
end
if isfield(cfg,'knudsen_transition_threshold')
    kn_threshold=cfg.knudsen_transition_threshold;
end
kn_hist=NaN(size(t_hist));
mean_free_path_hist=NaN(size(t_hist));

for j=1:numel(t_hist)
    st=stages(stage_index_hist(j));
    aero=aerodynamic_drag(st,max(0,h(j)),v(j));
    rho_hist(j)=aero.rho_kg_m3;
    q_hist(j)=aero.dynamic_pressure_Pa;
    cd_hist(j)=aero.Cd;
    mach_hist(j)=aero.mach;
    drag_hist(j)=aero.drag_N;
    drag_rate(j)=aero.drag_N/max(x_hist(j,5),eps);

    if isfinite(kn_length)
        rare=thesis_extended_atmosphere(max(0,h(j)),v(j),kn_length);
        kn_hist(j)=rare.knudsen;
        mean_free_path_hist(j)=rare.mean_free_path_m;
    end

    speed=max(v(j),eps);
    g=env.mu/r(j)^2;
    % Component of gravity opposing an ascending velocity vector.
    gravity_rate(j)=max(0,g*vr(j)/speed);
end
drag_cumulative=cumtrapz(t_hist,drag_rate);
gravity_cumulative=cumtrapz(t_hist,gravity_rate);

traj.rho = rho_hist;
traj.dynamic_pressure_Pa = q_hist;
traj.max_dynamic_pressure_Pa = max(q_hist);
traj.Cd = cd_hist;
traj.mach = mach_hist;
traj.drag_N = drag_hist;
traj.knudsen = kn_hist;
traj.mean_free_path_m = mean_free_path_hist;
traj.knudsen_characteristic_length_m = kn_length;
traj.knudsen_transition_threshold = kn_threshold;

transition_index=[];
if isfinite(kn_length)
    transition_index=find(kn_hist>=kn_threshold,1,'first');
end
traj.transition.detected=~isempty(transition_index);
if isempty(transition_index)
    traj.transition.index=NaN;
    traj.transition.time_s=NaN;
    traj.transition.altitude_m=NaN;
    traj.transition.knudsen=NaN;
    traj.transition.stage_index=NaN;
else
    traj.transition.index=transition_index;
    traj.transition.time_s=t_hist(transition_index);
    traj.transition.altitude_m=h(transition_index);
    traj.transition.knudsen=kn_hist(transition_index);
    traj.transition.stage_index=stage_index_hist(transition_index);
end

traj.losses.drag_m_s = drag_cumulative(end);
traj.losses.gravity_m_s = gravity_cumulative(end);
traj.losses.total_m_s = traj.losses.drag_m_s + traj.losses.gravity_m_s;
traj.loss_history.drag_m_s = drag_cumulative;
traj.loss_history.gravity_m_s = gravity_cumulative;
traj.loss_history.total_m_s = drag_cumulative + gravity_cumulative;

traj.traj_params = traj_params;
end
