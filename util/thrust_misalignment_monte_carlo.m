function out = thrust_misalignment_monte_carlo(sigma_rad,samples,opts)
%THRUST_MISALIGNMENT_MONTE_CARLO Pointing-error Monte Carlo statistics.
%
% Draws zero-mean Gaussian angular errors and reports the axial thrust
% efficiency cos(delta), transverse fraction sin(delta), and equivalent
% Delta-V loss fraction 1-cos(delta). This complements the deterministic
% thrust-vector misalignment already used by the trajectory equations.
%
% opts.seed default 1 for reproducible studies
% opts.mean_rad default 0
% opts.clip_rad default Inf

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'seed'), opts.seed=1; end
if ~isfield(opts,'mean_rad'), opts.mean_rad=0; end
if ~isfield(opts,'clip_rad'), opts.clip_rad=Inf; end
validateattributes(sigma_rad,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(samples,{'numeric'}, ...
    {'scalar','integer','>=',1});
validateattributes(opts.mean_rad,{'numeric'}, ...
    {'scalar','real','finite'});
rng(opts.seed,'twister');
delta=opts.mean_rad+sigma_rad*randn(samples,1);
if isfinite(opts.clip_rad)
    delta=max(-opts.clip_rad,min(opts.clip_rad,delta));
end
axial=cos(delta);
transverse=sin(delta);
loss=1-axial;

out.angle_rad=delta;
out.axial_thrust_fraction=axial;
out.transverse_thrust_fraction=transverse;
out.delta_v_loss_fraction=loss;
out.mean_delta_v_loss_fraction=mean(loss);
out.p95_abs_angle_rad=percentile(abs(delta),95);
out.p99_delta_v_loss_fraction=percentile(loss,99);
out.samples=samples;
out.seed=opts.seed;
out.model_status=['2026 stochastic extension; Gaussian pointing-error ', ...
    'sampling around the deterministic thrust-misalignment model.'];
end

function p=percentile(x,q)
x=sort(x(:));
if isempty(x), p=NaN; return; end
pos=1+(numel(x)-1)*q/100;
lo=floor(pos); hi=ceil(pos);
if lo==hi
    p=x(lo);
else
    p=x(lo)+(pos-lo)*(x(hi)-x(lo));
end
end
