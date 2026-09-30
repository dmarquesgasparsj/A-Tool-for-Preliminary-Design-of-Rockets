function c = evaluate_trajectory_constraints(traj,vehicle,limits,opts)
%EVALUATE_TRAJECTORY_CONSTRAINTS Evaluate Future-Work ascent constraints.
%
% Implements the four constraints explicitly proposed in the 2014 thesis:
%   - maximum dynamic pressure
%   - heat flux
%   - bending load
%   - axial acceleration
%
% Dynamic pressure comes directly from the trajectory when available.
% Heat flux is a 2026 extension using the Sutton-Graves stagnation-point
% correlation for Earth:
%   qdot = k * sqrt(rho/Rn) * V^3
% with default k = 1.7415e-4 in SI units.
%
% Bending is a preliminary normal-force model:
%   N = q * Aref * Cn_alpha * |alpha|
%   M = N * lever_arm
% It requires an explicit angle of attack and lever arm to be meaningful.
%
% Axial structural specific force is approximated as:
%   (T - D) / m
% and reported in g. Gravity is intentionally excluded because this metric
% represents longitudinal vehicle loading rather than inertial acceleration.
%
% VEHICLE requires stages with diameter_m and thrust_N, and TRAJ requires
% t, v, h, m, stage_index. LIMITS fields are optional:
%   max_q_Pa, max_heat_flux_W_m2, max_bending_moment_Nm,
%   max_axial_accel_g
%
% OPTS:
%   nose_radius_m
%   sutton_graves_k      default 1.7415e-4
%   angle_of_attack_rad  scalar or trajectory-length vector, default 0
%   normal_force_slope_per_rad default 2
%   bending_lever_arm_m  scalar or vector; default NaN

if nargin<3 || isempty(limits), limits=struct(); end
if nargin<4 || isempty(opts), opts=struct(); end
if ~isfield(opts,'sutton_graves_k'), opts.sutton_graves_k=1.7415e-4; end
if ~isfield(opts,'angle_of_attack_rad'), opts.angle_of_attack_rad=0; end
if ~isfield(opts,'normal_force_slope_per_rad')
    opts.normal_force_slope_per_rad=2;
end
if ~isfield(opts,'bending_lever_arm_m'), opts.bending_lever_arm_m=NaN; end
if ~isfield(opts,'g0'), opts.g0=9.80665; end

required={'t','v','h','m','stage_index'};
for i=1:numel(required)
    if ~isfield(traj,required{i})
        error('evaluate_trajectory_constraints:MissingTrajectoryField', ...
            'traj.%s is required.',required{i});
    end
end
if ~isfield(vehicle,'stages') || isempty(vehicle.stages)
    error('evaluate_trajectory_constraints:VehicleStages', ...
        'vehicle.stages is required.');
end
n=numel(traj.t);
if any([numel(traj.v),numel(traj.h),numel(traj.m), ...
        numel(traj.stage_index)]~=n)
    error('evaluate_trajectory_constraints:TrajectorySize', ...
        'Trajectory histories must have the same length.');
end

if isfield(traj,'rho') && numel(traj.rho)==n
    rho=reshape(traj.rho,1,[]);
else
    rho=zeros(1,n);
    for j=1:n
        a=thesis_extended_atmosphere(max(0,traj.h(j)),max(0,traj.v(j)));
        rho(j)=a.rho_kg_m3;
    end
end
v=reshape(traj.v,1,[]);
h=reshape(traj.h,1,[]);
m=reshape(traj.m,1,[]);
idx=reshape(traj.stage_index,1,[]);
if isfield(traj,'powered') && numel(traj.powered)==n
    powered=logical(reshape(traj.powered,1,[]));
else
    % Backward compatibility for trajectory producers that predate the
    % explicit powered/coast history.
    powered=true(1,n);
end

if isfield(traj,'dynamic_pressure_Pa') && ...
        numel(traj.dynamic_pressure_Pa)==n
    q=reshape(traj.dynamic_pressure_Pa,1,[]);
else
    q=0.5*rho.*v.^2;
end
if isfield(traj,'Cd') && numel(traj.Cd)==n
    Cd=reshape(traj.Cd,1,[]);
else
    Cd=zeros(1,n);
    for j=1:n
        a=thesis_extended_atmosphere(max(0,h(j)),max(0,v(j)));
        Cd(j)=thesis_cd_mach(a.mach);
    end
end

nose_radius=NaN;
if isfield(opts,'nose_radius_m') && isfinite(opts.nose_radius_m) && ...
        opts.nose_radius_m>0
    nose_radius=opts.nose_radius_m;
elseif isfield(vehicle,'nose_radius_m') && ...
        isfinite(vehicle.nose_radius_m) && vehicle.nose_radius_m>0
    nose_radius=vehicle.nose_radius_m;
elseif isfield(vehicle.stages(end),'diameter_m') && ...
        isfinite(vehicle.stages(end).diameter_m)
    nose_radius=vehicle.stages(end).diameter_m/2;
end
if ~isfinite(nose_radius) || nose_radius<=0
    error('evaluate_trajectory_constraints:NoseRadius', ...
        'A positive nose radius or final-stage diameter is required.');
end
heat=opts.sutton_graves_k*sqrt(rho./nose_radius).*v.^3;

alpha=expand_history(opts.angle_of_attack_rad,n, ...
    'angle_of_attack_rad');
lever=expand_history(opts.bending_lever_arm_m,n, ...
    'bending_lever_arm_m');
Cn=opts.normal_force_slope_per_rad;
validateattributes(Cn,{'numeric'},{'scalar','real','finite','nonnegative'});

drag=zeros(1,n);
thrust=zeros(1,n);
axial_g=zeros(1,n);
normal=zeros(1,n);
bending=NaN(1,n);
for j=1:n
    si=max(1,min(numel(vehicle.stages),round(idx(j))));
    st=vehicle.stages(si);
    if ~isfield(st,'diameter_m') || ~isfinite(st.diameter_m) || st.diameter_m<=0
        error('evaluate_trajectory_constraints:StageDiameter', ...
            'Stage %d requires diameter_m.',si);
    end
    A=pi*st.diameter_m^2/4;
    drag(j)=q(j)*Cd(j)*A;
    atm=thesis_extended_atmosphere(max(0,h(j)),max(0,v(j)));
    if powered(j)
        [thrust(j),~]=stage_thrust_at_ambient(st,atm.pressure_Pa);
    else
        thrust(j)=0;
    end
    axial_g(j)=(thrust(j)-drag(j))/max(m(j),eps)/opts.g0;
    normal(j)=q(j)*A*Cn*abs(alpha(j));
    if isfinite(lever(j)) && lever(j)>=0
        bending(j)=normal(j)*lever(j);
    end
end

[maxq,iq]=max(q);
[maxheat,ih]=max(heat);
[maxax,ia]=max(axial_g);
finite_bending=isfinite(bending);
if any(finite_bending)
    tmp=bending; tmp(~finite_bending)=-Inf;
    [maxbend,ib]=max(tmp);
else
    maxbend=NaN; ib=1;
end

lim.max_q_Pa=get_limit(limits,'max_q_Pa');
lim.max_heat_flux_W_m2=get_limit(limits,'max_heat_flux_W_m2');
lim.max_bending_moment_Nm=get_limit(limits,'max_bending_moment_Nm');
lim.max_axial_accel_g=get_limit(limits,'max_axial_accel_g');

pass_q=maxq<=lim.max_q_Pa;
pass_heat=maxheat<=lim.max_heat_flux_W_m2;
if isfinite(lim.max_bending_moment_Nm)
    pass_bending=isfinite(maxbend) && maxbend<=lim.max_bending_moment_Nm;
else
    pass_bending=true;
end
pass_axial=maxax<=lim.max_axial_accel_g;

c.dynamic_pressure_Pa=q;
c.heat_flux_W_m2=heat;
c.drag_N=drag;
c.thrust_N=thrust;
c.powered=powered;
c.axial_accel_g=axial_g;
c.normal_force_N=normal;
c.bending_moment_Nm=bending;
c.max_q_Pa=maxq;
c.max_q_time_s=traj.t(iq);
c.max_heat_flux_W_m2=maxheat;
c.max_heat_flux_time_s=traj.t(ih);
c.max_axial_accel_g=maxax;
c.max_axial_accel_time_s=traj.t(ia);
c.max_bending_moment_Nm=maxbend;
c.max_bending_time_s=traj.t(ib);
c.nose_radius_m=nose_radius;
c.limits=lim;
c.pass.dynamic_pressure=pass_q;
c.pass.heat_flux=pass_heat;
c.pass.bending=pass_bending;
c.pass.axial_acceleration=pass_axial;
c.all_pass=pass_q && pass_heat && pass_bending && pass_axial;
c.model_status=[ ...
    'Trajectory-constraint evaluator: q from ascent model; Sutton-Graves ', ...
    'heating and preliminary normal-force bending are 2026 extensions.'];
end

function v=expand_history(raw,n,name)
if isscalar(raw)
    v=repmat(raw,1,n);
elseif numel(raw)==n
    v=reshape(raw,1,[]);
else
    error('evaluate_trajectory_constraints:HistorySize', ...
        '%s must be scalar or trajectory length.',name);
end
end

function v=get_limit(s,name)
if isfield(s,name) && ~isempty(s.(name))
    v=s.(name);
    validateattributes(v,{'numeric'}, ...
        {'scalar','real','nonnegative'});
else
    v=Inf;
end
end
