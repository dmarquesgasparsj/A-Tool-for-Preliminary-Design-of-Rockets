function out = solid_grain_ballistics(grain,prop,opts)
%SOLID_GRAIN_BALLISTICS Preliminary solid-motor grain regression model.
%
% Supported geometries:
%   inhibited_core  internal cylindrical port, inhibited ends
%   bates           cylindrical port + both segment ends burning
%   end_burner      circular end-burning grain
%
% The equilibrium chamber pressure follows Saint-Robert burning:
%   rdot = a Pc^n
% and quasi-steady mass balance:
%   rho * Ab * rdot = Pc * At / cstar
%
% therefore:
%   Pc = (rho * Ab * a * cstar / At)^(1/(1-n))
%
% Required GRAIN fields:
%   geometry, outer_radius_m, segment_length_m
%   inner_radius_m for inhibited_core / bates
%   segments optional, default 1
%
% Required PROP fields:
%   density_kg_m3, burn_rate_a_m_s_Pa_n, burn_rate_n,
%   throat_area_m2, cstar_m_s
%
% Optional PROP fields gamma and nozzle_area_ratio add a thrust history.
% opts.ambient_pressure_Pa default 0; opts.samples default 301.
%
% This is a 2026 Future-Work extension. It is a quasi-steady conceptual
% model, not a combustion-stability or erosive-burning solver.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'samples'), opts.samples=301; end
if ~isfield(opts,'completion_fraction'), opts.completion_fraction=0.999; end
if ~isfield(opts,'ambient_pressure_Pa'), opts.ambient_pressure_Pa=0; end
if ~isfield(grain,'segments'), grain.segments=1; end

validateattributes(opts.samples,{'numeric'}, ...
    {'scalar','integer','>=',51});
validateattributes(opts.completion_fraction,{'numeric'}, ...
    {'scalar','real','>',0,'<',1});
validateattributes(grain.outer_radius_m,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(grain.segment_length_m,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(grain.segments,{'numeric'}, ...
    {'scalar','integer','positive'});
req={'density_kg_m3','burn_rate_a_m_s_Pa_n','burn_rate_n', ...
    'throat_area_m2','cstar_m_s'};
for i=1:numel(req)
    if ~isfield(prop,req{i}) || ~isfinite(prop.(req{i})) || prop.(req{i})<=0
        error('solid_grain_ballistics:MissingPropellantField', ...
            'prop.%s must be positive.',req{i});
    end
end
if prop.burn_rate_n>=1
    error('solid_grain_ballistics:BurnExponent', ...
        'Quasi-steady solution requires burn_rate_n < 1.');
end

Ro=grain.outer_radius_m;
L0=grain.segment_length_m;
N=grain.segments;
key=lower(char(grain.geometry));
switch key
    case {'inhibited_core','cylindrical_core'}
        Ri=require_inner(grain,Ro);
        webmax=Ro-Ri;
    case 'bates'
        Ri=require_inner(grain,Ro);
        webmax=min(Ro-Ri,L0/2);
    case {'end_burner','end'}
        Ri=0;
        webmax=L0;
    otherwise
        error('solid_grain_ballistics:Geometry', ...
            'Supported geometry: inhibited_core, bates, end_burner.');
end

w=linspace(0,opts.completion_fraction*webmax,opts.samples);
Ab=zeros(size(w)); V=zeros(size(w));
for k=1:numel(w)
    switch key
        case {'inhibited_core','cylindrical_core'}
            ri=Ri+w(k);
            Ab(k)=N*2*pi*ri*L0;
            V(k)=N*pi*(Ro^2-ri^2)*L0;
        case 'bates'
            ri=Ri+w(k);
            ell=max(L0-2*w(k),0);
            Ab(k)=N*(2*pi*ri*ell + 2*pi*(Ro^2-ri^2));
            V(k)=N*pi*(Ro^2-ri^2)*ell;
        otherwise
            ell=max(L0-w(k),0);
            Ab(k)=N*pi*Ro^2;
            V(k)=N*pi*Ro^2*ell;
    end
end

rho=prop.density_kg_m3;
a=prop.burn_rate_a_m_s_Pa_n;
n=prop.burn_rate_n;
At=prop.throat_area_m2;
cstar=prop.cstar_m_s;
Pc=(rho.*Ab.*a*cstar/At).^(1/(1-n));
rdot=a.*Pc.^n;
mdot=rho.*Ab.*rdot;
t=cumtrapz(w,1./max(rdot,eps));
mrem=rho.*V;
m0=mrem(1);
mburn=m0-mrem;

thrust=NaN(size(w)); Isp=NaN(size(w));
if isfield(prop,'gamma') && isfinite(prop.gamma) && prop.gamma>1 && ...
        isfield(prop,'nozzle_area_ratio') && ...
        isfinite(prop.nozzle_area_ratio) && prop.nozzle_area_ratio>=1
    for k=1:numel(w)
        st=struct('chamber_pressure_Pa',Pc(k), ...
            'nozzle_area_ratio',prop.nozzle_area_ratio, ...
            'gamma',prop.gamma,'cstar_m_s',cstar, ...
            'mass_flow_kg_s',mdot(k));
        q=pressure_aware_nozzle(st,opts.ambient_pressure_Pa);
        thrust(k)=q.thrust_N;
        Isp(k)=q.Isp_s;
    end
end

out.geometry=key;
out.web_m=w;
out.time_s=t;
out.burning_area_m2=Ab;
out.chamber_pressure_Pa=Pc;
out.burn_rate_m_s=rdot;
out.mass_flow_kg_s=mdot;
out.propellant_remaining_kg=mrem;
out.propellant_burned_kg=mburn;
out.initial_propellant_kg=m0;
out.web_limit_m=webmax;
out.simulated_web_fraction=w(end)/webmax;
out.burn_time_s=t(end);
out.mean_chamber_pressure_Pa=trapz(t,Pc)/max(t(end),eps);
out.peak_chamber_pressure_Pa=max(Pc);
out.mean_mass_flow_kg_s=trapz(t,mdot)/max(t(end),eps);
out.thrust_N=thrust;
out.Isp_s=Isp;
if all(isfinite(thrust))
    out.mean_thrust_N=trapz(t,thrust)/max(t(end),eps);
    out.peak_thrust_N=max(thrust);
else
    out.mean_thrust_N=NaN;
    out.peak_thrust_N=NaN;
end
out.model_status=['2026 quasi-steady solid-grain Future-Work extension; ', ...
    'Saint-Robert burn law with selectable grain geometry.'];
end

function Ri=require_inner(grain,Ro)
if ~isfield(grain,'inner_radius_m') || ~isfinite(grain.inner_radius_m) || ...
        grain.inner_radius_m<=0 || grain.inner_radius_m>=Ro
    error('solid_grain_ballistics:InnerRadius', ...
        'A positive inner_radius_m < outer_radius_m is required.');
end
Ri=grain.inner_radius_m;
end
