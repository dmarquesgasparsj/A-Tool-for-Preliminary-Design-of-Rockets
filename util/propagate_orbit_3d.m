function out = propagate_orbit_3d(initial,duration_s,opts)
%PROPAGATE_ORBIT_3D Long-coast Cartesian Earth-orbit propagator.
%
% initial.r_eci_m  3-vector
% initial.v_eci_m_s 3-vector
%
% opts.include_J2 default false
% opts.rel_tol default 1e-10
% opts.abs_tol default 1e-9
% opts.output_points default 301
%
% Intended for long coast phases and perturbation studies after ascent, not
% for atmospheric launch propagation.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'include_J2'), opts.include_J2=false; end
if ~isfield(opts,'rel_tol'), opts.rel_tol=1e-10; end
if ~isfield(opts,'abs_tol'), opts.abs_tol=1e-9; end
if ~isfield(opts,'output_points'), opts.output_points=301; end
validateattributes(duration_s,{'numeric'}, ...
    {'scalar','real','finite','positive'});
r0=initial.r_eci_m(:); v0=initial.v_eci_m_s(:);
if numel(r0)~=3 || numel(v0)~=3
    error('propagate_orbit_3d:Initial', ...
        'Initial r and v must be 3-vectors.');
end
y0=[r0;v0];
tspan=linspace(0,duration_s,opts.output_points);
odeopts=odeset('RelTol',opts.rel_tol,'AbsTol',opts.abs_tol);
gravopts=struct('include_J2',opts.include_J2);
[t,y]=ode45(@eom,tspan,y0,odeopts);
r=y(:,1:3); v=y(:,4:6);
env=earth_constants();
rmag=sqrt(sum(r.^2,2)); vmag=sqrt(sum(v.^2,2));
energy=0.5*vmag.^2-env.mu./rmag;

out.t_s=t;
out.r_eci_m=r;
out.v_eci_m_s=v;
out.radius_m=rmag;
out.altitude_m=rmag-env.Re;
out.speed_m_s=vmag;
out.specific_energy_J_kg=energy;
out.energy_definition='two-body central-potential specific energy only';
out.include_J2=logical(opts.include_J2);
out.duration_s=duration_s;
out.initial=initial;
out.model_status='3D Cartesian coast propagation with optional Earth J2.';
    function dy=eom(~,yy)
        rr=yy(1:3);
        aa=earth_gravity_acceleration(rr,gravopts);
        dy=[yy(4:6);aa(:)];
    end
end
