function n = pressure_aware_nozzle(stage,ambient_pressure_Pa,opts)
%PRESSURE_AWARE_NOZZLE Isentropic nozzle geometry and thrust performance.
%
% This is a NEW 2026 extension motivated by the thesis Future Work request
% to include chamber pressure, exit pressure and nozzle areas. The equations
% are standard isentropic/choked-flow rocket-nozzle relations; they were not
% implemented in the surviving 2014 source.
%
% Required STAGE:
%   chamber_pressure_Pa
%   nozzle_area_ratio       Ae/At
%   gamma                   exhaust-gas heat-capacity ratio
%   cstar_m_s               characteristic velocity
% and either:
%   mass_flow_kg_s
% or thrust_N + Isp_s       (used only to infer mdot = T/(Isp*g0))
%
% Optional nozzle shell geometry:
%   nozzle_half_angle_deg   default 15
%   nozzle_wall_thickness_m
%   nozzle_material_density_kg_m3
%
% Outputs include throat/exit area, exit Mach/pressure, thrust coefficient,
% thrust at the supplied ambient pressure and optional conical shell mass.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'g0'), opts.g0=9.80665; end
if ~isfield(opts,'mach_upper_bound'), opts.mach_upper_bound=20; end
validateattributes(ambient_pressure_Pa,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});

req={'chamber_pressure_Pa','nozzle_area_ratio','gamma','cstar_m_s'};
for i=1:numel(req)
    if ~isfield(stage,req{i}) || ~isfinite(stage.(req{i})) || stage.(req{i})<=0
        error('pressure_aware_nozzle:MissingField', ...
            'stage.%s must be positive.',req{i});
    end
end
Pc=stage.chamber_pressure_Pa;
epsA=stage.nozzle_area_ratio;
gam=stage.gamma;
cstar=stage.cstar_m_s;
if gam<=1
    error('pressure_aware_nozzle:Gamma','gamma must be greater than 1.');
end
if epsA<1
    error('pressure_aware_nozzle:AreaRatio', ...
        'nozzle_area_ratio must be >= 1.');
end

if isfield(stage,'mass_flow_kg_s') && ...
        isfinite(stage.mass_flow_kg_s) && stage.mass_flow_kg_s>0
    mdot=stage.mass_flow_kg_s;
elseif isfield(stage,'thrust_N') && isfield(stage,'Isp_s') && ...
        isfinite(stage.thrust_N) && stage.thrust_N>0 && ...
        isfinite(stage.Isp_s) && stage.Isp_s>0
    mdot=stage.thrust_N/(stage.Isp_s*opts.g0);
else
    error('pressure_aware_nozzle:MassFlow', ...
        'Provide mass_flow_kg_s or positive thrust_N and Isp_s.');
end

Me=solve_exit_mach(epsA,gam,opts.mach_upper_bound);
Pe_Pc=(1+(gam-1)/2*Me^2)^(-gam/(gam-1));
Pe=Pc*Pe_Pc;
At=mdot*cstar/Pc;
Ae=epsA*At;

momentum_cf=sqrt((2*gam^2/(gam-1)) * ...
    (2/(gam+1))^((gam+1)/(gam-1)) * ...
    (1-Pe_Pc^((gam-1)/gam)));
pressure_cf=(Pe-ambient_pressure_Pa)/Pc*epsA;
Cf=momentum_cf+pressure_cf;
F=Cf*Pc*At;
Isp=F/(mdot*opts.g0);

rt=sqrt(At/pi);
re=sqrt(Ae/pi);
if isfield(stage,'nozzle_half_angle_deg') && ...
        isfinite(stage.nozzle_half_angle_deg)
    half_angle=stage.nozzle_half_angle_deg;
else
    half_angle=15;
end
validateattributes(half_angle,{'numeric'}, ...
    {'scalar','real','finite','>',0,'<',90});
L=(re-rt)/tan(deg2rad(half_angle));
slant=sqrt((re-rt)^2+L^2);
shell_area=pi*(rt+re)*slant;
shell_mass=NaN;
if isfield(stage,'nozzle_wall_thickness_m') && ...
        isfield(stage,'nozzle_material_density_kg_m3') && ...
        isfinite(stage.nozzle_wall_thickness_m) && ...
        isfinite(stage.nozzle_material_density_kg_m3) && ...
        stage.nozzle_wall_thickness_m>0 && ...
        stage.nozzle_material_density_kg_m3>0
    shell_mass=shell_area*stage.nozzle_wall_thickness_m* ...
        stage.nozzle_material_density_kg_m3;
end

n.mass_flow_kg_s=mdot;
n.throat_area_m2=At;
n.exit_area_m2=Ae;
n.throat_radius_m=rt;
n.exit_radius_m=re;
n.exit_mach=Me;
n.exit_pressure_Pa=Pe;
n.exit_to_chamber_pressure_ratio=Pe_Pc;
n.momentum_thrust_coefficient=momentum_cf;
n.pressure_thrust_coefficient=pressure_cf;
n.thrust_coefficient=Cf;
n.thrust_N=F;
n.Isp_s=Isp;
n.ambient_pressure_Pa=ambient_pressure_Pa;
n.chamber_pressure_Pa=Pc;
n.nozzle_length_m=L;
n.nozzle_shell_area_m2=shell_area;
n.nozzle_shell_mass_kg=shell_mass;
n.half_angle_deg=half_angle;
n.source=['2026 extension using standard isentropic/choked rocket-nozzle ', ...
    'relations; thesis Future Work requested Pc, Pe and nozzle areas.'];
end

function M=solve_exit_mach(area_ratio,gamma,upper)
if abs(area_ratio-1)<1e-12
    M=1;
    return;
end
lo=1+1e-9; hi=upper;
if area_mach(hi,gamma)<area_ratio
    error('pressure_aware_nozzle:MachBracket', ...
        'Increase mach_upper_bound for this area ratio.');
end
for i=1:100
    mid=(lo+hi)/2;
    val=area_mach(mid,gamma);
    if abs(val-area_ratio)/area_ratio<1e-12
        M=mid;
        return;
    end
    if val>area_ratio, hi=mid; else, lo=mid; end
end
M=(lo+hi)/2;
end

function ar=area_mach(M,gamma)
ar=(1./M).*((2/(gamma+1)).* ...
    (1+(gamma-1)/2.*M.^2)).^((gamma+1)/(2*(gamma-1)));
end
