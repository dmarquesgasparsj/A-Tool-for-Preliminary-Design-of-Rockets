function result = thesis_free_flight_tpbvp(initial,target,propulsion,opts)
%THESIS_FREE_FLIGHT_TPBVP Minimum-time free-flight phase from the 2014 thesis.
%
% Clean reconstruction of thesis equations (3.33)-(3.47):
%   xdot  = Vx
%   ydot  = Vy
%   Vxdot = (T/m) * (-lambda3 / sqrt(lambda3^2+lambda4^2))
%   Vydot = (T/m) * (-lambda4 / sqrt(lambda3^2+lambda4^2)) - g
%   lambda1dot = 0
%   lambda2dot = 0
%   lambda3dot = -lambda1
%   lambda4dot = -lambda2
%
% The terminal horizontal position and final time are free. Boundary
% conditions enforce target y, Vx, Vy, lambda1(tf)=0 and H(tf)+1=0.
% MATLAB bvp4c solves the state/costate BVP on nondimensional tau=t/tf.
%
% Coordinates are local Cartesian. The equations are invariant to a
% constant offset in y, so callers may consistently use altitude or radius.
%
% Required INITIAL fields:
%   x_m, y_m, vx_m_s, vy_m_s, mass_kg
% Required TARGET fields:
%   y_m, vx_m_s
% Optional TARGET:
%   vy_m_s (default 0)
% Required PROPULSION:
%   thrust_N
% and either:
%   mdot_kg_s
% or Isp_s (mdot = T/(Isp*g0)).
% If mdot>0, propellant_available_kg is required to bound tf before burnout.
%
% Options:
%   g_m_s2          default local Earth gravity at initial y
%   tf_guess_s      default 50% of available burn time, or 100 s
%   mesh_points     default 41
%   output_points   default 201
%   rel_tol         default 1e-6
%   abs_tol         default 1e-8
%   max_nodes       default 10000
%
% This restores the mathematical TPBVP formulation. Coupling it to the
% Kn=5 atmospheric transition and multi-stage propulsion schedule is a
% separate integration step.

if nargin<4 || isempty(opts), opts=struct(); end
req_i={'x_m','y_m','vx_m_s','vy_m_s','mass_kg'};
for k=1:numel(req_i)
    if ~isfield(initial,req_i{k})
        error('thesis_free_flight_tpbvp:MissingInitial', ...
            'Initial state requires %s.',req_i{k});
    end
end
req_t={'y_m','vx_m_s'};
for k=1:numel(req_t)
    if ~isfield(target,req_t{k})
        error('thesis_free_flight_tpbvp:MissingTarget', ...
            'Target requires %s.',req_t{k});
    end
end
if ~isfield(target,'vy_m_s'), target.vy_m_s=0; end
if ~isfield(propulsion,'thrust_N')
    error('thesis_free_flight_tpbvp:MissingThrust', ...
        'propulsion.thrust_N is required.');
end

values=[initial.x_m initial.y_m initial.vx_m_s initial.vy_m_s ...
    initial.mass_kg target.y_m target.vx_m_s target.vy_m_s ...
    propulsion.thrust_N];
validateattributes(values,{'numeric'},{'real','finite'});
validateattributes(initial.mass_kg,{'numeric'}, ...
    {'scalar','positive','finite'});
validateattributes(propulsion.thrust_N,{'numeric'}, ...
    {'scalar','positive','finite'});

g0=9.80665;
if isfield(propulsion,'mdot_kg_s') && ~isempty(propulsion.mdot_kg_s)
    mdot=propulsion.mdot_kg_s;
elseif isfield(propulsion,'Isp_s') && ~isempty(propulsion.Isp_s)
    validateattributes(propulsion.Isp_s,{'numeric'}, ...
        {'scalar','positive','finite'});
    mdot=propulsion.thrust_N/(propulsion.Isp_s*g0);
else
    error('thesis_free_flight_tpbvp:MissingMassFlow', ...
        'Provide propulsion.mdot_kg_s or propulsion.Isp_s.');
end
validateattributes(mdot,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});

if ~isfield(opts,'mesh_points'), opts.mesh_points=41; end
if ~isfield(opts,'output_points'), opts.output_points=201; end
if ~isfield(opts,'rel_tol'), opts.rel_tol=1e-6; end
if ~isfield(opts,'abs_tol'), opts.abs_tol=1e-8; end
if ~isfield(opts,'max_nodes'), opts.max_nodes=10000; end
validateattributes(opts.mesh_points,{'numeric'}, ...
    {'scalar','integer','>=',11});
validateattributes(opts.output_points,{'numeric'}, ...
    {'scalar','integer','>=',21});

env=earth_constants();
if ~isfield(opts,'g_m_s2')
    altitude=max(0,initial.y_m);
    opts.g_m_s2=env.g0*(env.Re/(env.Re+altitude))^2;
end
g=opts.g_m_s2;
validateattributes(g,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});

if mdot>0
    if ~isfield(propulsion,'propellant_available_kg')
        error('thesis_free_flight_tpbvp:MissingPropellantAvailable', ...
            ['propellant_available_kg is required for positive mdot so ', ...
             'the free final time cannot cross burnout.']);
    end
    validateattributes(propulsion.propellant_available_kg,{'numeric'}, ...
        {'scalar','real','finite','positive','<',initial.mass_kg});
    max_time=propulsion.propellant_available_kg/mdot;
else
    max_time=Inf;
end

if ~isfield(opts,'tf_guess_s')
    if isfinite(max_time)
        opts.tf_guess_s=0.5*max_time;
    else
        opts.tf_guess_s=100;
    end
end
validateattributes(opts.tf_guess_s,{'numeric'}, ...
    {'scalar','real','finite','positive'});
if isfinite(max_time) && opts.tf_guess_s>=max_time
    opts.tf_guess_s=0.8*max_time;
end

% Parameterize tf so bvp4c cannot propose a negative time or cross burnout.
if isfinite(max_time)
    frac=min(max(opts.tf_guess_s/max_time,1e-6),1-1e-6);
    p0=log(frac/(1-frac));
else
    p0=log(opts.tf_guess_s);
end

mesh=linspace(0,1,opts.mesh_points);
guess=@(tau) initial_guess(tau,opts.tf_guess_s);
solinit=bvpinit(mesh,guess,p0);
bvp_opts=bvpset('RelTol',opts.rel_tol,'AbsTol',opts.abs_tol, ...
    'NMax',opts.max_nodes);

try
    sol=bvp4c(@odefun,@bcfun,solinit,bvp_opts);
catch ME
    wrapped=MException('thesis_free_flight_tpbvp:NoConvergence', ...
        'bvp4c failed to converge: %s',ME.message);
    wrapped=addCause(wrapped,ME);
    throw(wrapped);
end

tf=decode_tf(sol.parameters);
tau=linspace(0,1,opts.output_points);
Y=deval(sol,tau);
time=tau*tf;
mass=initial.mass_kg-mdot*time;
if any(mass<=0)
    error('thesis_free_flight_tpbvp:MassDepleted', ...
        'TPBVP solution crosses zero vehicle mass.');
end

norm_costate=sqrt(Y(7,:).^2+Y(8,:).^2);
ux=-Y(7,:)./max(norm_costate,eps);
uy=-Y(8,:)./max(norm_costate,eps);
theta=atan2(uy,ux);

bcres=bcfun(Y(:,1),Y(:,end),sol.parameters);
Hf=hamiltonian(Y(:,end),tf);

result.converged=max(abs(bcres))<max(1e-5,10*opts.abs_tol);
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
result.steering_angle_rad=theta;
result.steering_unit=[ux;uy];
result.propellant_used_kg=mdot*tf;
result.boundary_residual=bcres;
result.max_boundary_residual=max(abs(bcres));
result.final_hamiltonian=Hf;
result.target=target;
result.initial=initial;
result.propulsion=propulsion;
result.g_m_s2=g;
result.model_status=[ ...
    '2014 minimum-time TPBVP equations reconstructed with bvp4c; ', ...
    'single continuous thrust/mass-flow segment, constant gravity.'];

    function tf_local=decode_tf(p)
        if isfinite(max_time)
            s=1/(1+exp(-p(1)));
            tf_local=max_time*s;
        else
            tf_local=exp(p(1));
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

        m_guess=max(initial.mass_kg-mdot*t,eps);
        accel=propulsion.thrust_N/m_guess;
        ax=(target.vx_m_s-initial.vx_m_s)/max(tf_guess,eps);
        ay=(target.vy_m_s-initial.vy_m_s)/max(tf_guess,eps)+g;
        anorm=hypot(ax,ay);
        if anorm<1e-9
            u=[1;0];
        else
            u=[ax;ay]/anorm;
        end
        a0=max(accel,1e-9);
        l1=0;
        l2=0;
        l3=-u(1)/a0;
        l4=-u(2)/a0;
        z=[x;y;vx;vy;l1;l2;l3;l4];
    end

    function dY=odefun(tau_local,Ylocal,p)
        tf_local=decode_tf(p);
        t=tau_local*tf_local;
        m=initial.mass_kg-mdot*t;
        m=max(m,eps);
        denom=sqrt(Ylocal(7)^2+Ylocal(8)^2);
        denom=max(denom,eps);
        ux_local=-Ylocal(7)/denom;
        uy_local=-Ylocal(8)/denom;
        accel=propulsion.thrust_N/m;

        ddt=[Ylocal(3); ...
             Ylocal(4); ...
             accel*ux_local; ...
             accel*uy_local-g; ...
             0; ...
             0; ...
             -Ylocal(5); ...
             -Ylocal(6)];
        dY=tf_local*ddt;
    end

    function residual=bcfun(Y0,Yf,p)
        tf_local=decode_tf(p);
        H=hamiltonian(Yf,tf_local);
        residual=[ ...
            Y0(1)-initial.x_m; ...
            Y0(2)-initial.y_m; ...
            Y0(3)-initial.vx_m_s; ...
            Y0(4)-initial.vy_m_s; ...
            Yf(2)-target.y_m; ...
            Yf(3)-target.vx_m_s; ...
            Yf(4)-target.vy_m_s; ...
            Yf(5); ...
            H+1];
    end

    function H=hamiltonian(Yf,tf_local)
        m=initial.mass_kg-mdot*tf_local;
        denom=max(hypot(Yf(7),Yf(8)),eps);
        ux_local=-Yf(7)/denom;
        uy_local=-Yf(8)/denom;
        accel=propulsion.thrust_N/max(m,eps);
        H=Yf(5)*Yf(3)+Yf(6)*Yf(4)+ ...
            Yf(7)*(accel*ux_local)+ ...
            Yf(8)*(accel*uy_local-g);
    end
end
