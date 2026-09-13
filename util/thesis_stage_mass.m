function [ms_kg, mp_kg, k] = thesis_stage_mass(payload_kg, delta_v_ms, Isp_s, epsilon, g0)
%THESIS_STAGE_MASS Stage sizing equations from the 2014 MSc thesis.
%
%   [MS, MP, K] = THESIS_STAGE_MASS(PAYLOAD, DELTAV, ISP, EPSILON)
%   implements equations (5.1)-(5.3) of "A Tool for Preliminary Design
%   of Rockets" (Gaspar, 2014):
%
%       k  = exp(DeltaV / (g * Isp))
%       ms = epsilon (k-1) / (1-epsilon*k) * mpl
%       mp = (k-1)(1-epsilon) / (1-k*epsilon) * mpl
%
%   PAYLOAD is the mass of everything above the stage, as defined in the
%   thesis. The function is intentionally small so the original equations
%   can be regression-tested independently from later reconstruction work.
%
%   G0 defaults to standard gravity, 9.80665 m/s^2.

if nargin < 5 || isempty(g0)
    g0 = 9.80665;
end

validateattributes(payload_kg, {'numeric'}, ...
    {'scalar','real','finite','nonnegative'}, mfilename, 'payload_kg');
validateattributes(delta_v_ms, {'numeric'}, ...
    {'scalar','real','finite','nonnegative'}, mfilename, 'delta_v_ms');
validateattributes(Isp_s, {'numeric'}, ...
    {'scalar','real','finite','positive'}, mfilename, 'Isp_s');
validateattributes(epsilon, {'numeric'}, ...
    {'scalar','real','finite','>=',0,'<',1}, mfilename, 'epsilon');
validateattributes(g0, {'numeric'}, ...
    {'scalar','real','finite','positive'}, mfilename, 'g0');

k = exp(delta_v_ms / (g0 * Isp_s));
den = 1 - epsilon * k;

% A physically meaningful solution requires epsilon*k < 1.
if den <= 0
    error('thesis_stage_mass:InfeasibleStage', ...
        ['No finite stage mass exists for this combination of Delta-V, ', ...
         'Isp and structural factor (epsilon*k must be < 1).']);
end

ms_kg = epsilon * (k - 1) / den * payload_kg;
mp_kg = (k - 1) * (1 - epsilon) / den * payload_kg;
end
