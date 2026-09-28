function geom = thesis_nose_cone_geometry(shape,L,R,opts)
%THESIS_NOSE_CONE_GEOMETRY Profiles from Appendix A of the 2014 thesis.
%
% geom = thesis_nose_cone_geometry(shape,L,R)
% returns a sampled axisymmetric profile and numerical volume/surface area.
%
% shape:
%   'ogive'    Appendix A.1.1. opts.k in [0,1], default 1 (tangent ogive).
%   'power'    Appendix A.1.2. opts.kappa in (0,1], default 0.75.
%   'ellipse'  Appendix A.1.3.
%   'haack'    Appendix A.1.4. opts.k=0 Von Karman, 1/3 LV-Haack.
%
% x=0 is the tip and x=L is the body joint, so r(0)=0 and r(L)=R.
% These equations define geometry only. The thesis did NOT implement a
% nose-shape-specific drag law; that was explicitly left as Future Work.

if nargin<4 || isempty(opts), opts=struct(); end
validateattributes(L,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(R,{'numeric'},{'scalar','real','finite','positive'});
if ~isfield(opts,'samples'), opts.samples=401; end
validateattributes(opts.samples,{'numeric'}, ...
    {'scalar','integer','finite','>=',21});
x=linspace(0,L,opts.samples);
key=lower(strtrim(char(shape)));

switch key
    case 'ogive'
        if ~isfield(opts,'k'), opts.k=1; end
        k=opts.k;
        validateattributes(k,{'numeric'}, ...
            {'scalar','real','finite','>=',0,'<=',1});
        if k < 1e-10
            r=R*x/L; % conical limiting case described in Appendix A
            rho=Inf;
        else
            rho2=((L^2+R^2)*(((2-k)*L)^2+(k*R)^2))/(4*(k*R)^2);
            rho=sqrt(rho2);
            inside1=max(0,rho2-(L/k-x).^2);
            inside0=max(0,rho2-(L/k)^2);
            r=sqrt(inside1)-sqrt(inside0);
        end
        parameters=struct('k',k,'rho_m',rho);

    case 'power'
        if ~isfield(opts,'kappa'), opts.kappa=0.75; end
        kappa=opts.kappa;
        validateattributes(kappa,{'numeric'}, ...
            {'scalar','real','finite','>',0,'<=',1});
        r=R*(x/L).^kappa;
        parameters=struct('kappa',kappa);

    case {'ellipse','elliptical'}
        r=R*sqrt(max(0,1-(1-x/L).^2));
        parameters=struct();

    case {'haack','von-karman','von karman'}
        if ~isfield(opts,'k'), opts.k=0; end
        k=opts.k;
        validateattributes(k,{'numeric'}, ...
            {'scalar','real','finite','>=',0,'<=',1/3});
        theta=acos(max(-1,min(1,1-2*x/L)));
        inside=theta-0.5*sin(2*theta)+k*sin(theta).^3;
        r=(R/sqrt(pi))*sqrt(max(0,inside));
        parameters=struct('k',k);

    otherwise
        error('thesis_nose_cone_geometry:UnknownShape', ...
            'Supported shapes: ogive, power, ellipse, haack.');
end

% Pin exact end points against floating-point roundoff.
r(1)=0;
r(end)=R;
volume=trapz(x,pi*r.^2);
drdx=gradient(r,x);
surface=trapz(x,2*pi*r.*sqrt(1+drdx.^2));

geom.shape=key;
geom.length_m=L;
geom.base_radius_m=R;
geom.x_m=x;
geom.r_m=r;
geom.volume_m3=volume;
geom.wetted_area_m2=surface;
geom.frontal_area_m2=pi*R^2;
geom.parameters=parameters;
geom.source='Gaspar MSc thesis (2014), Appendix A';
end
