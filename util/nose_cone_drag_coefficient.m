function [Cd,detail] = nose_cone_drag_coefficient(M,shape,L,R,opts)
%NOSE_CONE_DRAG_COEFFICIENT Shape-aware preliminary nose pressure drag.
%
% Uses the thesis Appendix-A geometry and a modified-Newtonian forebody
% pressure model in the hypersonic regime. The model is smoothly blended
% with the thesis Cd(Mach) polynomial between configurable Mach numbers,
% because modified Newtonian theory is not a sub/transonic model.
%
% This is a 2026 Future-Work extension, not a recovered 2014 equation.
% It estimates forebody pressure drag only; viscous/base/interference drag
% can be added explicitly through opts.additional_Cd.
%
% opts.gamma            default 1.4
% opts.blend_mach_start default 2
% opts.blend_mach_end   default 4
% opts.additional_Cd    default 0
% opts.geometry_options forwarded to thesis_nose_cone_geometry

if nargin<5 || isempty(opts), opts=struct(); end
if ~isfield(opts,'gamma'), opts.gamma=1.4; end
if ~isfield(opts,'blend_mach_start'), opts.blend_mach_start=2; end
if ~isfield(opts,'blend_mach_end'), opts.blend_mach_end=4; end
if ~isfield(opts,'additional_Cd'), opts.additional_Cd=0; end
if ~isfield(opts,'geometry_options'), opts.geometry_options=struct(); end
validateattributes(M,{'numeric'},{'real','finite','nonnegative'});
validateattributes(opts.gamma,{'numeric'}, ...
    {'scalar','real','finite','>',1});
validateattributes(opts.blend_mach_start,{'numeric'}, ...
    {'scalar','real','finite','>=',1});
validateattributes(opts.blend_mach_end,{'numeric'}, ...
    {'scalar','real','finite','>',opts.blend_mach_start});
validateattributes(opts.additional_Cd,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});

g=thesis_nose_cone_geometry(shape,L,R,opts.geometry_options);
x=g.x_m; r=g.r_m;
drdx=gradient(r,x);
drdx=max(drdx,0);
theta=atan(drdx);
Aref=pi*R^2;

Cd=zeros(size(M));
Cd_hyp=zeros(size(M));
Cpmax=zeros(size(M));
blend=zeros(size(M));
baseline=max(thesis_cd_mach(M),0);

for k=1:numel(M)
    Mk=M(k);
    if Mk>1+1e-8
        Cpmax(k)=stagnation_pressure_coefficient(Mk,opts.gamma);
        Cp=Cpmax(k)*sin(theta).^2;
        axial_integrand=Cp.*2*pi.*r.*drdx;
        Cd_hyp(k)=trapz(x,axial_integrand)/Aref + opts.additional_Cd;
    else
        Cpmax(k)=NaN;
        Cd_hyp(k)=baseline(k);
    end
    z=(Mk-opts.blend_mach_start)/ ...
        (opts.blend_mach_end-opts.blend_mach_start);
    z=max(0,min(1,z));
    blend(k)=z*z*(3-2*z);
    Cd(k)=(1-blend(k))*baseline(k)+blend(k)*Cd_hyp(k);
end

detail.shape=g.shape;
detail.geometry=g;
detail.baseline_thesis_Cd=baseline;
detail.hypersonic_pressure_Cd=Cd_hyp;
detail.stagnation_Cp=Cpmax;
detail.blend_weight=blend;
detail.gamma=opts.gamma;
detail.model_status=['2026 shape-specific Future-Work extension: ', ...
    'modified-Newtonian forebody pressure drag blended with thesis Cd(Mach).'];
detail.reference=['NASA modified-Newtonian pressure relation Cp = ', ...
    'Cp,max sin^2(theta); Appendix-A geometry from Gaspar (2014).'];
end

function Cp0=stagnation_pressure_coefficient(M,gamma)
% Total pressure behind a normal shock, normalized to freestream dynamic p.
p2p1=1 + 2*gamma/(gamma+1)*(M^2-1);
M2sq=(1+(gamma-1)/2*M^2)/(gamma*M^2-(gamma-1)/2);
p02p2=(1+(gamma-1)/2*M2sq)^(gamma/(gamma-1));
p02p1=p2p1*p02p2;
Cp0=(p02p1-1)/(0.5*gamma*M^2);
end
