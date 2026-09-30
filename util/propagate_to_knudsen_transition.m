function phase = propagate_to_knudsen_transition(cfg,mission,traj_params,payload_mass)
%PROPAGATE_TO_KNUDSEN_TRANSITION Powered atmospheric ascent to Kn = threshold.
%
% Integrates the same staged 2D polar equations used by
% simulate_gravity_turn, including generalized inclined/air-launch initial
% conditions, but terminates exactly when the reconstructed
% Knudsen number reaches cfg.knudsen_transition_threshold (default 5).
%
% The returned transition state retains the currently burning stage and its
% remaining propellant. No stage is jettisoned at the transition itself.
% This provides the boundary state for the thesis free-flight phase.

cfg=validate_config(cfg);
validateattributes(payload_mass,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
if ~isfield(cfg,'knudsen_characteristic_length_m') || ...
        ~isfinite(cfg.knudsen_characteristic_length_m) || ...
        cfg.knudsen_characteristic_length_m<=0
    error('propagate_to_knudsen_transition:MissingLength', ...
        'A positive cfg.knudsen_characteristic_length_m is required.');
end
if ~isfield(cfg,'knudsen_transition_threshold')
    cfg.knudsen_transition_threshold=5;
end
Lkn=cfg.knudsen_characteristic_length_m;
threshold=cfg.knudsen_transition_threshold;

required_mission={'target_alt','launch_lat'};
for k=1:numel(required_mission)
    if ~isfield(mission,required_mission{k})
        error('propagate_to_knudsen_transition:Mission', ...
            'Mission is missing %s.',required_mission{k});
    end
end
env=earth_constants();
env.launch_lat=mission.launch_lat;
if isfield(mission,'include_earth_rotation')
    env.atmosphere_rotates=logical(mission.include_earth_rotation);
else
    env.atmosphere_rotates=true;
end
stages=cfg.stages;
N=numel(stages);
m0=payload_mass+sum([stages.mp_kg])+sum([stages.ms_kg]);
init=launch_initial_conditions(mission,m0);
state=init.state;
[ufun,guidance_meta]=launch_guidance(mission,traj_params,init);

t0=0;
t_hist=[];
x_hist=[];
stage_hist=[];
events=repmat(struct('name','','t_start',0,'t_end',0, ...
    'burnout',false,'mass_start_kg',0,'mass_end_kg',0, ...
    'mass_after_separation_kg',NaN),1,N);
transition=struct('detected',false,'time_s',NaN,'state',NaN(5,1), ...
    'stage_index',NaN,'remaining_propellant_kg',NaN, ...
    'burned_propellant_kg',NaN,'knudsen',NaN,'altitude_m',NaN);

% A generalized air launch may already start at or above the thesis
% atmospheric/exo-atmospheric boundary. In that case the hand-off is
% immediate and no propellant is burned before free flight.
air0=atmosphere_relative_velocity_2d(state(1),state(3),state(4),env);
atm0=thesis_extended_atmosphere(init.altitude_m,air0.speed_m_s,Lkn);
if atm0.knudsen>=threshold
    t_hist=0;
    x_hist=state.';
    stage_hist=1;
    transition.detected=true;
    transition.time_s=0;
    transition.state=state;
    transition.stage_index=1;
    transition.remaining_propellant_kg=stages(1).mp_kg;
    transition.burned_propellant_kg=0;
    transition.knudsen=atm0.knudsen;
    transition.altitude_m=init.altitude_m;
    events(1).name=stages(1).name;
    events(1).t_start=0;
    events(1).t_end=0;
    events(1).burnout=false;
    events(1).mass_start_kg=m0;
    events(1).mass_end_kg=m0;
end

if ~transition.detected
for i=1:N
    st=stages(i);
    mdot=st.thrust_N/(st.Isp_s*env.g0);
    tburn=st.mp_kg/mdot;
    m_start=state(5);

    ode_opts=odeset('RelTol',1e-7,'AbsTol',1e-8, ...
        'Events',@(t,x) kn_event(t,x,Lkn,threshold,env));
    eom=@(t,x) equations_of_motion(t,x,env,st,ufun);
    [t_seg,x_seg,te,xe]=ode45(eom,[t0,t0+tburn],state,ode_opts);

    if i>1 && ~isempty(t_seg)
        t_seg=t_seg(2:end);
        x_seg=x_seg(2:end,:);
    end
    t_hist=[t_hist;t_seg]; %#ok<AGROW>
    x_hist=[x_hist;x_seg]; %#ok<AGROW>
    stage_hist=[stage_hist;repmat(i,numel(t_seg),1)]; %#ok<AGROW>

    events(i).name=st.name;
    events(i).t_start=t0;
    events(i).mass_start_kg=m_start;

    if ~isempty(te)
        t_transition=te(end);
        x_transition=xe(end,:)';
        burned=min(st.mp_kg,max(0,mdot*(t_transition-t0)));
        remaining=max(0,st.mp_kg-burned);

        % Pin analytical mass consumption at the transition.
        x_transition(5)=m_start-burned;
        if ~isempty(x_hist)
            x_hist(end,5)=x_transition(5);
        end

        air_transition=atmosphere_relative_velocity_2d( ...
            x_transition(1),x_transition(3),x_transition(4),env);
        atm=thesis_extended_atmosphere( ...
            max(0,x_transition(1)-env.Re), ...
            air_transition.speed_m_s,Lkn);

        transition.detected=true;
        transition.time_s=t_transition;
        transition.state=x_transition;
        transition.stage_index=i;
        transition.remaining_propellant_kg=remaining;
        transition.burned_propellant_kg=burned;
        transition.knudsen=atm.knudsen;
        transition.altitude_m=x_transition(1)-env.Re;

        events(i).t_end=t_transition;
        events(i).burnout=false;
        events(i).mass_end_kg=x_transition(5);
        break;
    end

    % Full stage burnout and serial separation.
    m_end=m_start-st.mp_kg;
    if ~isempty(x_hist), x_hist(end,5)=m_end; end
    events(i).t_end=t0+tburn;
    events(i).burnout=true;
    events(i).mass_end_kg=m_end;

    if i<N
        m_after=m_end-st.ms_kg;
    else
        m_after=m_end;
    end
    events(i).mass_after_separation_kg=m_after;
    state=x_seg(end,:)';
    state(5)=m_after;
    t0=t0+tburn;
end
end

if isempty(t_hist)
    error('propagate_to_knudsen_transition:EmptyTrajectory', ...
        'Atmospheric propagation produced no samples.');
end

r=x_hist(:,1);
vr=x_hist(:,3);
vtheta=x_hist(:,4);
h=r-env.Re;
v=hypot(vr,vtheta);
gamma=atan2(vr,vtheta);

rho=zeros(size(t_hist));
q=zeros(size(t_hist));
Cd=zeros(size(t_hist));
Mach=zeros(size(t_hist));
Kn=zeros(size(t_hist));
drag_rate=zeros(size(t_hist));
gravity_rate=zeros(size(t_hist));
air_speed=zeros(size(t_hist));
for j=1:numel(t_hist)
    st=stages(stage_hist(j));
    air=atmosphere_relative_velocity_2d(r(j),vr(j),vtheta(j),env);
    air_speed(j)=air.speed_m_s;
    aero=aerodynamic_drag(st,max(0,h(j)),air.speed_m_s);
    rare=thesis_extended_atmosphere(max(0,h(j)),air.speed_m_s,Lkn);
    rho(j)=aero.rho_kg_m3;
    q(j)=aero.dynamic_pressure_Pa;
    Cd(j)=aero.Cd;
    Mach(j)=aero.mach;
    Kn(j)=rare.knudsen;
    drag_rate(j)=aero.drag_N/max(x_hist(j,5),eps);
    gravity_rate(j)=max(0,(env.mu/r(j)^2)*vr(j)/max(v(j),eps));
end

phase.t=t_hist;
phase.r=r;
phase.theta=x_hist(:,2);
phase.vr=vr;
phase.vtheta=vtheta;
phase.h=h;
phase.v=v;
phase.gamma=gamma;
phase.m=x_hist(:,5);
phase.stage_index=stage_hist;
phase.air_speed_m_s=air_speed;
phase.rho=rho;
phase.dynamic_pressure_Pa=q;
phase.Cd=Cd;
phase.mach=Mach;
phase.knudsen=Kn;
phase.max_dynamic_pressure_Pa=max(q);
if numel(t_hist)<2
    % Immediate Kn hand-off at launch: no elapsed atmospheric time means
    % zero integrated drag/gravity loss by definition.
    phase.losses.drag_m_s=0;
    phase.losses.gravity_m_s=0;
else
    phase.losses.drag_m_s=trapz(t_hist,drag_rate);
    phase.losses.gravity_m_s=trapz(t_hist,gravity_rate);
end
phase.losses.total_m_s=phase.losses.drag_m_s+phase.losses.gravity_m_s;
phase.transition=transition;
phase.stage_events=events;
phase.cfg=cfg;
phase.traj_params=traj_params;
phase.payload_kg=payload_mass;
phase.m0=m0;
phase.initial_conditions=init;
phase.guidance=guidance_meta;
end

function [value,isterminal,direction]=kn_event(~,x,Lkn,threshold,env)
h=max(0,x(1)-env.Re);
air=atmosphere_relative_velocity_2d(x(1),x(3),x(4),env);
atm=thesis_extended_atmosphere(h,air.speed_m_s,Lkn);
value=atm.knudsen-threshold;
isterminal=1;
direction=1;
end
