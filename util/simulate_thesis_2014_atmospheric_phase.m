function phase = simulate_thesis_2014_atmospheric_phase(cfg,opts)
%SIMULATE_THESIS_2014_ATMOSPHERIC_PHASE Historical thesis-mode ascent.
%
% Reconstructs the atmospheric trajectory specifically for historical
% validation, keeping it separate from the modern spherical-Earth solver.
%
% Thesis-mode assumptions:
%   - no Earth rotation;
%   - initial V = 0, vertical flight to a specified altitude;
%   - a small flight-path-angle seed starts the gravity turn;
%   - gravity-turn equations (3.1)-(3.4) are used directly;
%   - local gravity follows thesis Eq. (3.55), g=g0/(1+h/Re);
%   - Cd follows thesis Eq. (3.49);
%   - stage mass flow is mp / documented burn time, matching the recovered
%     development wrapper rather than deriving mdot from thrust and Isp;
%   - the atmospheric phase ends at Kn=5 using last-stage radius.
%
% This is a historical-validation model, not the preferred modern dynamics.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'drag_reference')
    opts.drag_reference='active_stage';
end
if ~isfield(opts,'rel_tol'), opts.rel_tol=1e-7; end
if ~isfield(opts,'abs_tol'), opts.abs_tol=1e-8; end
if ~isfield(opts,'g0'), opts.g0=9.81; end
if ~isfield(opts,'earth_radius_m'), opts.earth_radius_m=6378e3; end
if ~isfield(opts,'initial_altitude_m'), opts.initial_altitude_m=0; end

required={'stages','payload_kg','gravity_turn_altitude_m', ...
    'gravity_turn_seed_gamma_rad','knudsen_threshold', ...
    'knudsen_characteristic_length_m'};
for i=1:numel(required)
    if ~isfield(cfg,required{i})
        error('simulate_thesis_2014_atmospheric_phase:MissingField', ...
            'Configuration requires %s.',required{i});
    end
end
stages=cfg.stages;
N=numel(stages);
m0=cfg.payload_kg+sum([stages.mp_kg])+sum([stages.ms_kg]);
g0=opts.g0;
Re=opts.earth_radius_m;
Lkn=cfg.knudsen_characteristic_length_m;
threshold=cfg.knudsen_threshold;

% Phase A: vertical ascent. State [v; x; h; m].
state_v=[0;0;opts.initial_altitude_m;m0];
stage_index=1;
stage_start_t=0;
stage_burned=0;
t_all=[]; v_all=[]; gamma_all=[]; x_all=[]; h_all=[]; m_all=[]; idx_all=[];

% Historical Vega reaches 500 m during stage 1. The generic loop allows
% stage boundaries should another fixture require them.
while state_v(3)<cfg.gravity_turn_altitude_m
    if stage_index>N
        error('simulate_thesis_2014_atmospheric_phase:NoGravityTurn', ...
            'All stages ended before gravity-turn altitude was reached.');
    end
    st=stages(stage_index);
    mdot=st.mp_kg/st.burn_time_s;
    remaining_time=(st.mp_kg-stage_burned)/mdot;
    ode=@(t,y) vertical_eom(t,y,st,mdot);
    ev=@(t,y) altitude_event(t,y,cfg.gravity_turn_altitude_m);
    o=odeset('RelTol',opts.rel_tol,'AbsTol',opts.abs_tol,'Events',ev);
    [tt,yy,te,ye]=ode45(ode,[stage_start_t stage_start_t+remaining_time],state_v,o);

    append_vertical(tt,yy,stage_index);
    burned=mdot*(tt(end)-stage_start_t);
    stage_burned=stage_burned+burned;

    if ~isempty(te)
        state_v=ye(end,:)';
        state_v(4)=m0-total_burned_mass(t_all,idx_all,stages);
        break;
    end

    % Stage burnout and separation.
    state_v=yy(end,:)';
    state_v(4)=state_v(4)-st.ms_kg;
    stage_index=stage_index+1;
    stage_start_t=tt(end);
    stage_burned=0;
end

% Restart with the small FPA nudge described in the thesis/recovered tests.
vgt=state_v(1);
xgt=state_v(2);
hgt=state_v(3);
mgt=state_v(4);
gamma0=cfg.gravity_turn_seed_gamma_rad;
state=[vgt;gamma0;xgt;hgt;mgt];

transition=struct('detected',false,'time_s',NaN,'altitude_m',NaN, ...
    'velocity_m_s',NaN,'gamma_rad',NaN,'stage_index',NaN, ...
    'knudsen',NaN,'mass_kg',NaN,'remaining_propellant_kg',NaN);

% Continue the active stage from the propellant already consumed vertically.
while stage_index<=N
    st=stages(stage_index);
    mdot=st.mp_kg/st.burn_time_s;
    if stage_burned==0 && stage_start_t==0
        % For stage 1, infer consumption up to the GT start.
        stage_burned=min(st.mp_kg,mdot*t_all(end));
        stage_start_t=t_all(end);
    end
    remaining_prop=max(0,st.mp_kg-stage_burned);
    remaining_time=remaining_prop/mdot;
    if remaining_time<=0
        state(5)=state(5)-st.ms_kg;
        stage_index=stage_index+1;
        stage_burned=0;
        stage_start_t=t_all(end);
        continue;
    end

    ode=@(t,y) gravity_turn_eom(t,y,st,mdot);
    ev=@(t,y) kn_event(t,y,Lkn,threshold);
    o=odeset('RelTol',opts.rel_tol,'AbsTol',opts.abs_tol,'Events',ev);
    t_start=t_all(end);
    [tt,yy,te,ye]=ode45(ode,[t_start t_start+remaining_time],state,o);

    append_gt(tt,yy,stage_index);
    burn_this=mdot*(tt(end)-t_start);
    stage_burned=stage_burned+burn_this;

    if ~isempty(te)
        ytr=ye(end,:)';
        atm=thesis_extended_atmosphere(ytr(4),ytr(1),Lkn);
        transition.detected=true;
        transition.time_s=te(end);
        transition.altitude_m=ytr(4);
        transition.velocity_m_s=ytr(1);
        transition.gamma_rad=ytr(2);
        transition.stage_index=stage_index;
        transition.knudsen=atm.knudsen;
        transition.mass_kg=ytr(5);
        transition.remaining_propellant_kg=max(0,st.mp_kg-stage_burned);
        state=ytr;
        break;
    end

    % Burnout: drop dry mass. Coast periods are not entered because the
    % historical atmospheric validation target occurs before Vega P80 burnout.
    state=yy(end,:)';
    if stage_index<N
        state(5)=state(5)-st.ms_kg;
    end
    stage_index=stage_index+1;
    stage_burned=0;
    stage_start_t=tt(end);
end

% Recompute aerodynamic and Kn histories consistently.
rho=zeros(size(t_all)); q=zeros(size(t_all)); Cd=zeros(size(t_all));
Mach=zeros(size(t_all)); Kn=zeros(size(t_all));
for j=1:numel(t_all)
    st=stages(idx_all(j));
    diameter=select_drag_diameter(stages,idx_all(j),opts.drag_reference);
    A=pi*diameter^2/4;
    atm=thesis_extended_atmosphere(max(0,h_all(j)),max(0,v_all(j)),Lkn);
    rho(j)=atm.rho_kg_m3;
    Mach(j)=atm.mach;
    Cd(j)=thesis_cd_mach(Mach(j));
    q(j)=0.5*rho(j)*v_all(j)^2;
    Kn(j)=atm.knudsen;
    %#ok<NASGU> A used in EOM with the same selection
end

[~,iq]=max(q);
phase.t=t_all;
phase.v=v_all;
phase.gamma=gamma_all;
phase.x=x_all;
phase.h=h_all;
phase.m=m_all;
phase.stage_index=idx_all;
phase.rho=rho;
phase.dynamic_pressure_Pa=q;
phase.Cd=Cd;
phase.mach=Mach;
phase.knudsen=Kn;
phase.max_dynamic_pressure_Pa=q(iq);
phase.max_q_altitude_m=h_all(iq);
phase.transition=transition;
phase.reference_GLOW_kg=m0;
phase.options=opts;
phase.model_status=[ ...
    'Historical 2014 thesis-mode atmospheric reconstruction using ', ...
    'Eqs. 3.1-3.4, Eq. 3.49, Eq. 3.55 and Kn=5.'];
phase.provenance_note=[ ...
    'Recovered RocketDynEq was not available; vertical-to-GT switching ', ...
    'and drag-area interpretation are explicit reconstruction choices.'];

    function dy=vertical_eom(~,y,st,mdot)
        v=max(y(1),0); h=max(y(3),0); m=max(y(4),eps);
        D=drag_force(st,h,v);
        g=local_g(h);
        dy=[(st.thrust_N-D)/m-g; 0; v; -mdot];
    end

    function dy=gravity_turn_eom(~,y,st,mdot)
        v=max(y(1),1e-6); gamma=y(2); h=max(y(4),0); m=max(y(5),eps);
        D=drag_force(st,h,v);
        g=local_g(h);
        curvature=v^2/(Re+h);
        dv=(st.thrust_N-D)/m-(g-curvature)*sin(gamma);
        dgamma=-(g-curvature)*cos(gamma)/v;
        dx=v*cos(gamma);
        dh=v*sin(gamma);
        dy=[dv;dgamma;dx;dh;-mdot];
    end

    function D=drag_force(st,h,v)
        diameter=select_drag_diameter(stages,stage_index,opts.drag_reference);
        area=pi*diameter^2/4;
        atm=thesis_extended_atmosphere(h,v);
        Cdlocal=thesis_cd_mach(atm.mach);
        D=0.5*atm.rho_kg_m3*v^2*Cdlocal*area;
    end

    function g=local_g(h)
        % Equation (3.55) as printed in the 2014 thesis.
        g=g0/(1+h/Re);
    end

    function append_vertical(tt,yy,idx)
        if ~isempty(t_all) && ~isempty(tt)
            tt=tt(2:end); yy=yy(2:end,:);
        end
        t_all=[t_all;tt]; %#ok<AGROW>
        v_all=[v_all;yy(:,1)]; %#ok<AGROW>
        gamma_all=[gamma_all;repmat(pi/2,numel(tt),1)]; %#ok<AGROW>
        x_all=[x_all;yy(:,2)]; %#ok<AGROW>
        h_all=[h_all;yy(:,3)]; %#ok<AGROW>
        m_all=[m_all;yy(:,4)]; %#ok<AGROW>
        idx_all=[idx_all;repmat(idx,numel(tt),1)]; %#ok<AGROW>
    end

    function append_gt(tt,yy,idx)
        if ~isempty(t_all) && ~isempty(tt)
            tt=tt(2:end); yy=yy(2:end,:);
        end
        t_all=[t_all;tt]; %#ok<AGROW>
        v_all=[v_all;yy(:,1)]; %#ok<AGROW>
        gamma_all=[gamma_all;yy(:,2)]; %#ok<AGROW>
        x_all=[x_all;yy(:,3)]; %#ok<AGROW>
        h_all=[h_all;yy(:,4)]; %#ok<AGROW>
        m_all=[m_all;yy(:,5)]; %#ok<AGROW>
        idx_all=[idx_all;repmat(idx,numel(tt),1)]; %#ok<AGROW>
    end

    function [value,isterminal,direction]=altitude_event(~,y,target_h)
        value=y(3)-target_h;
        isterminal=1;
        direction=1;
    end

    function [value,isterminal,direction]=kn_event(~,y,L,limit)
        atm=thesis_extended_atmosphere(max(0,y(4)),max(0,y(1)),L);
        value=atm.knudsen-limit;
        isterminal=1;
        direction=1;
    end
end

function d=select_drag_diameter(stages,idx,policy)
switch lower(char(policy))
    case 'active_stage'
        d=stages(idx).diameter_m;
    case 'core'
        d=stages(1).diameter_m;
    case 'upper_stack'
        d=stages(min(idx+1,numel(stages))).diameter_m;
    otherwise
        error('simulate_thesis_2014_atmospheric_phase:DragReference', ...
            'Unknown drag_reference policy: %s.',char(policy));
end
end

function burned=total_burned_mass(t,idx,stages)
% Only used to pin the vertical-transition mass. Reconstruct consumed
% propellant from stage time membership and documented burn rates.
burned=0;
if numel(t)<2, return; end
for i=1:numel(stages)
    mask=idx==i;
    if nnz(mask)>=2
        ti=t(mask);
        burned=burned+(stages(i).mp_kg/stages(i).burn_time_s)*(ti(end)-ti(1));
    end
end
end
