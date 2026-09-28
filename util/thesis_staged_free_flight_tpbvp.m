function result = thesis_staged_free_flight_tpbvp(initial,target,schedule,opts)
%THESIS_STAGED_FREE_FLIGHT_TPBVP Modern serial-stage extension of thesis TPBVP.
%
% Uses the same state/costate and minimum-time boundary conditions as
% thesis_free_flight_tpbvp(), while allowing a known sequence of remaining
% serial burns. Thrust and mass flow are piecewise constant; spent dry mass
% is dropped at fixed burnout times.
%
% This is a 2026 extension needed to couple the thesis TPBVP formulation to
% arbitrary serial-stage configurations. The original thesis equations
% describe the optimal-control law; the staged schedule handling here is
% explicitly modern reconstruction infrastructure.

if nargin<4 || isempty(opts), opts=struct(); end
required_initial={'x_m','y_m','vx_m_s','vy_m_s','mass_kg'};
for i=1:numel(required_initial)
    if ~isfield(initial,required_initial{i})
        error('thesis_staged_free_flight_tpbvp:Initial', ...
            'Missing initial field %s.',required_initial{i});
    end
end
if ~isfield(target,'y_m') || ~isfield(target,'vx_m_s')
    error('thesis_staged_free_flight_tpbvp:Target', ...
        'Target requires y_m and vx_m_s.');
end
if ~isfield(target,'vy_m_s'), target.vy_m_s=0; end
if ~isstruct(schedule) || isempty(schedule)
    error('thesis_staged_free_flight_tpbvp:Schedule', ...
        'A nonempty propulsion schedule is required.');
end

required_seg={'thrust_N','mdot_kg_s','duration_s','dry_mass_drop_after_kg'};
for k=1:numel(schedule)
    for j=1:numel(required_seg)
        if ~isfield(schedule(k),required_seg{j})
            error('thesis_staged_free_flight_tpbvp:ScheduleField', ...
                'Schedule segment %d lacks %s.',k,required_seg{j});
        end
    end
    validateattributes(schedule(k).thrust_N,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(schedule(k).mdot_kg_s,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    validateattributes(schedule(k).duration_s,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(schedule(k).dry_mass_drop_after_kg,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
end

max_time=sum([schedule.duration_s]);
validateattributes(initial.mass_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'});
if ~isfield(opts,'tf_guess_s'), opts.tf_guess_s=0.65*max_time; end
if ~isfield(opts,'mesh_points'), opts.mesh_points=61; end
if ~isfield(opts,'output_points'), opts.output_points=301; end
if ~isfield(opts,'rel_tol'), opts.rel_tol=1e-5; end
if ~isfield(opts,'abs_tol'), opts.abs_tol=1e-7; end
if ~isfield(opts,'max_nodes'), opts.max_nodes=20000; end
if ~isfield(opts,'g_m_s2')
    env=earth_constants();
    altitude=max(0,initial.y_m);
    opts.g_m_s2=env.g0*(env.Re/(env.Re+altitude))^2;
end
g=opts.g_m_s2;
validateattributes(g,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
opts.tf_guess_s=min(max(opts.tf_guess_s,1e-6),0.98*max_time);

% Verify that the supplied initial mass can survive the scheduled drops.
mcheck=initial.mass_kg;
for k=1:numel(schedule)
    mcheck=mcheck-schedule(k).mdot_kg_s*schedule(k).duration_s;
    if k<numel(schedule)
        mcheck=mcheck-schedule(k).dry_mass_drop_after_kg;
    end
    if mcheck<=0
        error('thesis_staged_free_flight_tpbvp:MassSchedule', ...
            'Remaining schedule depletes vehicle mass by segment %d.',k);
    end
end

frac=opts.tf_guess_s/max_time;
p0=log(frac/(1-frac));
mesh=linspace(0,1,opts.mesh_points);
solinit=bvpinit(mesh,@(tau) initial_guess(tau,opts.tf_guess_s),p0);
bvp_opts=bvpset('RelTol',opts.rel_tol,'AbsTol',opts.abs_tol, ...
    'NMax',opts.max_nodes);

try
    sol=bvp4c(@odefun,@bcfun,solinit,bvp_opts);
catch ME
    wrapped=MException('thesis_staged_free_flight_tpbvp:NoConvergence', ...
        'Staged bvp4c solve failed: %s',ME.message);
    wrapped=addCause(wrapped,ME);
    throw(wrapped);
end

tf=decode_tf(sol.parameters);
tau=linspace(0,1,opts.output_points);
Y=deval(sol,tau);
time=tau*tf;
mass=zeros(size(time));
thrust=zeros(size(time));
stage_idx=zeros(size(time));
for j=1:numel(time)
    [mass(j),thrust(j),stage_idx(j)]=vehicle_at(time(j));
end
normc=sqrt(Y(7,:).^2+Y(8,:).^2);
ux=-Y(7,:)./max(normc,eps);
uy=-Y(8,:)./max(normc,eps);
theta=atan2(uy,ux);
bcres=bcfun(Y(:,1),Y(:,end),sol.parameters);

result.converged=max(abs(bcres))<max(1e-4,10*opts.abs_tol);
result.tf_s=tf;
result.t_s=time;
result.tau=tau;
result.state=Y(1:4,:);
result.costate=Y(5:8,:);
result.x_m=Y(1,:);
result.y_m=Y(2,:);
result.vx_m_s=Y(3,:);
result.vy_m_s=Y(4,:);
result.mass_kg=mass;
result.thrust_N=thrust;
result.schedule_index=stage_idx;
result.steering_angle_rad=theta;
result.steering_unit=[ux;uy];
result.boundary_residual=bcres;
result.max_boundary_residual=max(abs(bcres));
result.final_hamiltonian=hamiltonian(Y(:,end),tf);
result.schedule=schedule;
result.max_available_burn_time_s=max_time;
result.burn_fraction=tf/max_time;
result.g_m_s2=g;
result.initial=initial;
result.target=target;
result.model_status=[ ...
    '2026 staged extension of the 2014 minimum-time TPBVP; ', ...
    'piecewise serial thrust/mass schedule with fixed stage burnouts.'];

    function tf_local=decode_tf(p)
        s=1/(1+exp(-p(1)));
        tf_local=max_time*s;
    end

    function [m,T,idx]=vehicle_at(t)
        m=initial.mass_kg;
        elapsed=0;
        idx=numel(schedule);
        T=schedule(end).thrust_N;
        for kk=1:numel(schedule)
            duration=schedule(kk).duration_s;
            if t<=elapsed+duration || kk==numel(schedule)
                dt=min(max(t-elapsed,0),duration);
                m=m-schedule(kk).mdot_kg_s*dt;
                T=schedule(kk).thrust_N;
                idx=kk;
                return;
            end
            m=m-schedule(kk).mdot_kg_s*duration;
            m=m-schedule(kk).dry_mass_drop_after_kg;
            elapsed=elapsed+duration;
        end
    end

    function z=initial_guess(tau_local,tf_guess)
        t=tau_local*tf_guess;
        s=tau_local;
        vx=initial.vx_m_s+(target.vx_m_s-initial.vx_m_s)*s;
        vy=initial.vy_m_s+(target.vy_m_s-initial.vy_m_s)*s;
        x=initial.x_m+initial.vx_m_s*t + ...
            0.5*(target.vx_m_s-initial.vx_m_s)*tf_guess*s.^2;
        y=initial.y_m+(target.y_m-initial.y_m)*(3*s.^2-2*s.^3);

        [m0,T0]=vehicle_at(0);
        a0=T0/m0;
        ax=(target.vx_m_s-initial.vx_m_s)/max(tf_guess,eps);
        ay=(target.vy_m_s-initial.vy_m_s)/max(tf_guess,eps)+g;
        an=hypot(ax,ay);
        if an<1e-12, u=[1;0]; else, u=[ax;ay]/an; end
        l1=0; l2=0;
        l3=-u(1)/max(a0,eps);
        l4=-u(2)/max(a0,eps);
        z=[x;y;vx;vy;l1;l2;l3;l4];
    end

    function dY=odefun(tau_local,Y,p)
        tf_local=decode_tf(p);
        t=tau_local*tf_local;
        [m,T]=vehicle_at(t);
        denom=max(hypot(Y(7),Y(8)),eps);
        ux_local=-Y(7)/denom;
        uy_local=-Y(8)/denom;
        accel=T/max(m,eps);
        ddt=[Y(3);Y(4); ...
            accel*ux_local;accel*uy_local-g; ...
            0;0;-Y(5);-Y(6)];
        dY=tf_local*ddt;
    end

    function residual=bcfun(Y0,Yf,p)
        tf_local=decode_tf(p);
        H=hamiltonian(Yf,tf_local);
        residual=[Y0(1)-initial.x_m; ...
            Y0(2)-initial.y_m; ...
            Y0(3)-initial.vx_m_s; ...
            Y0(4)-initial.vy_m_s; ...
            Yf(2)-target.y_m; ...
            Yf(3)-target.vx_m_s; ...
            Yf(4)-target.vy_m_s; ...
            Yf(5); ...
            H+1];
    end

    function H=hamiltonian(Y,t)
        [m,T]=vehicle_at(t);
        denom=max(hypot(Y(7),Y(8)),eps);
        ux_local=-Y(7)/denom;
        uy_local=-Y(8)/denom;
        accel=T/max(m,eps);
        H=Y(5)*Y(3)+Y(6)*Y(4)+ ...
            Y(7)*(accel*ux_local)+ ...
            Y(8)*(accel*uy_local-g);
    end
end
