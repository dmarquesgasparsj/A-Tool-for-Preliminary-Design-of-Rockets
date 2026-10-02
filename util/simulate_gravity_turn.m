function traj = simulate_gravity_turn(cfg, mission, traj_params, payload_mass)
%SIMULATE_GRAVITY_TURN Integrate a simplified 2D staged ascent.
%   Historical/default missions fly vertically, perform a short pitch kick
%   and then follow a gravity turn. Modern missions may start at arbitrary
%   altitude, speed and flight-path angle for inclined or air launch.
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

env = earth_constants();
Re = env.Re;
env.launch_lat = mission.launch_lat;
if isfield(mission,'include_earth_rotation')
    env.atmosphere_rotates = logical(mission.include_earth_rotation);
else
    env.atmosphere_rotates = true;
end

stages = cfg.stages;
N = numel(stages);
m0 = payload_mass + sum([stages.mp_kg]) + sum([stages.ms_kg]);

% State = [radius; longitude-like angle; radial velocity; tangential velocity; mass]
init = launch_initial_conditions(mission,m0);
state = init.state;
t0 = 0;
t_hist = [];
x_hist = [];
stage_index_hist = [];
stage_events = repmat(struct('name','','t_start',0,'t_burnout',0, ...
    'mass_start_kg',0,'mass_burnout_kg',0,'mass_after_sep_kg',0), 1, N);

% Guidance profile. Historical ground launches retain the original
% vertical/kick law; inclined and air launches use their initial FPA.
[ufun,guidance_meta] = launch_guidance(mission,traj_params,init);

ode_opts = odeset('RelTol',1e-7,'AbsTol',1e-8);

for i = 1:N
    st=stages(i);
    nominal_mdot=st.thrust_N/(st.Isp_s*env.g0);
    nominal_tburn=st.mp_kg/nominal_mdot;
    m_start=state(5);
    m_end_burn=m_start-st.mp_kg;

    % Integrate to propellant depletion rather than assuming constant
    % nominal thrust. This preserves exact behaviour for legacy constant
    % thrust while allowing pressure-aware and constraint-throttled stages.
    min_throttle=0.2;
    if isfield(st,'constraint_control') && isstruct(st.constraint_control) && ...
            isfield(st.constraint_control,'min_throttle')
        min_throttle=max(0.01,st.constraint_control.min_throttle);
    elseif isfield(st,'throttle') && isnumeric(st.throttle) && isscalar(st.throttle)
        min_throttle=max(0.01,st.throttle);
    end
    max_duration=2*nominal_tburn/min_throttle;
    eom=@(t,x) equations_of_motion(t,x,env,st,ufun);
    stage_opts=odeset(ode_opts,'Events', ...
        @(t,x) burnout_event(t,x,m_end_burn));
    [t_seg,x_seg,te,xe]=ode45(eom,[t0,t0+max_duration],state,stage_opts);
    if isempty(te) && x_seg(end,5)>m_end_burn+max(1e-6,1e-9*m_start)
        error('simulate_gravity_turn:BurnoutNotReached', ...
            'Stage %d did not consume its propellant within the burn horizon.',i);
    end
    if ~isempty(xe)
        x_seg(end,:)=xe(end,:);
        t_seg(end)=te(end);
    end
    x_seg(end,5)=m_end_burn;
    tburn=t_seg(end)-t0;

    if i>1
        t_seg=t_seg(2:end);
        x_seg=x_seg(2:end,:);
    end
    t_hist=[t_hist;t_seg]; %#ok<AGROW>
    x_hist=[x_hist;x_seg]; %#ok<AGROW>
    stage_index_hist=[stage_index_hist;repmat(i,numel(t_seg),1)]; %#ok<AGROW>

    if i<N
        m_after_sep=m_end_burn-st.ms_kg;
    else
        m_after_sep=m_end_burn;
    end

    stage_events(i).name=st.name;
    stage_events(i).t_start=t0;
    stage_events(i).t_burnout=t0+tburn;
    stage_events(i).mass_start_kg=m_start;
    stage_events(i).mass_burnout_kg=m_end_burn;
    stage_events(i).mass_after_sep_kg=m_after_sep;

    state=x_seg(end,:)';
    state(5)=m_after_sep;
    t0=t0+tburn;
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

air_speed_hist=zeros(size(t_hist));
for j=1:numel(t_hist)
    st=stages(stage_index_hist(j));
    air=atmosphere_relative_velocity_2d(r(j),vr(j),vtheta(j),env);
    air_speed_hist(j)=air.speed_m_s;
    aero=aerodynamic_drag(st,max(0,h(j)),air.speed_m_s);
    rho_hist(j)=aero.rho_kg_m3;
    q_hist(j)=aero.dynamic_pressure_Pa;
    cd_hist(j)=aero.Cd;
    mach_hist(j)=aero.mach;
    drag_hist(j)=aero.drag_N;
    drag_rate(j)=aero.drag_N/max(x_hist(j,5),eps);

    if isfinite(kn_length)
        rare=thesis_extended_atmosphere(max(0,h(j)),air.speed_m_s,kn_length);
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

traj.air_speed_m_s = air_speed_hist;
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
traj.initial_conditions = init;
traj.guidance = guidance_meta;

% Reconstruct throttle/thrust histories for diagnostics.
traj.throttle=ones(size(t_hist));
traj.thrust_N=zeros(size(t_hist));
for j=1:numel(t_hist)
    st=stages(stage_index_hist(j));
    aero=aerodynamic_drag(st,max(0,h(j)),air_speed_hist(j));
    [Tnom,~]=stage_thrust_at_ambient(st,aero.pressure_Pa);
    cmd=1;
    if isfield(st,'throttle') && ~isempty(st.throttle)
        if isa(st.throttle,'function_handle')
            cmd=st.throttle(t_hist(j),x_hist(j,:)');
        else
            cmd=st.throttle;
        end
    end
    if isfield(st,'constraint_limits') && isstruct(st.constraint_limits) && ...
            ~isempty(fieldnames(st.constraint_limits))
        ctrl=struct();
        if isfield(st,'constraint_control') && isstruct(st.constraint_control)
            ctrl=st.constraint_control;
        end
        [uc,~]=constraint_aware_throttle(aero,x_hist(j,:)',st,env, ...
            st.constraint_limits,ctrl);
        cmd=min(cmd,uc);
    end
    traj.throttle(j)=cmd;
    traj.thrust_N(j)=Tnom*cmd;
end
end

function [value,isterminal,direction]=burnout_event(~,x,target_mass)
value=x(5)-target_mass;
isterminal=1;
direction=-1;
end
