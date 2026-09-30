function a = earth_gravity_acceleration(r_eci_m,opts)
%EARTH_GRAVITY_ACCELERATION Central Earth gravity with optional J2.
%
% r_eci_m: 3xN or Nx3 Earth-centred inertial position [m].
%
% opts.include_J2 (default false)
% opts.mu_m3_s2  (default earth_constants().mu)
% opts.Re_m      (default earth_constants().Re)
% opts.J2        (default earth_constants().J2)
%
% J2 is the first non-spherical Earth term. The implementation uses the
% standard Cartesian first-order zonal-harmonic acceleration.

if nargin<2 || isempty(opts), opts=struct(); end
env=earth_constants();
if ~isfield(opts,'include_J2'), opts.include_J2=false; end
if ~isfield(opts,'mu_m3_s2'), opts.mu_m3_s2=env.mu; end
if ~isfield(opts,'Re_m'), opts.Re_m=env.Re; end
if ~isfield(opts,'J2'), opts.J2=env.J2; end

R=r_eci_m;
transpose_back=false;
if size(R,1)~=3 && size(R,2)==3
    R=R.';
    transpose_back=true;
end
if size(R,1)~=3
    error('earth_gravity_acceleration:Dimension', ...
        'Position must be 3xN or Nx3.');
end
rmag=sqrt(sum(R.^2,1));
if any(~isfinite(rmag)) || any(rmag<=0)
    error('earth_gravity_acceleration:Position', ...
        'Position magnitudes must be positive and finite.');
end
mu=opts.mu_m3_s2;
a=-mu*R./(rmag.^3);

if logical(opts.include_J2)
    x=R(1,:); y=R(2,:); z=R(3,:);
    z2r2=(z.^2)./(rmag.^2);
    factor=1.5*opts.J2*mu*opts.Re_m^2./(rmag.^5);
    aJ=[factor.*x.*(5*z2r2-1); ...
        factor.*y.*(5*z2r2-1); ...
        factor.*z.*(5*z2r2-3)];
    a=a+aJ;
end
if transpose_back, a=a.'; end
end
