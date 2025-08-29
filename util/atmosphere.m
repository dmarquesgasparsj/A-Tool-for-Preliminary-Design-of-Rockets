function [rho, a, T, P] = atmosphere(h)
% ATMOSPHERE  International Standard Atmosphere (ISA) model.
%   [rho, a, T, P] = ATMOSPHERE(h) returns air density RHO, speed of sound A,
%   temperature T and pressure P at geometric altitude h [m] based on the
%   1976 U.S. Standard Atmosphere up to 86 km. For altitudes above the last
%   defined layer an isothermal extrapolation is used.
%
%   This function is compatible with the previous signature where calling
%   RHO = ATMOSPHERE(h) returns only the density.

% Constants
R = 287.05;        % Specific gas constant for air [J/(kg·K)]
gamma = 1.4;      % Ratio of specific heats
g0 = 9.80665;     % Sea-level gravity [m/s^2]

% Layer base altitudes [m] and lapse rates [K/m]
hb = [0, 11000, 20000, 32000, 47000, 51000, 71000, 84852];
L  = [-0.0065, 0, 0.0010, 0.0028, 0, -0.0028, -0.0020];

% Precompute temperature and pressure at layer bases
Tb = zeros(size(hb));
Pb = zeros(size(hb));
Tb(1) = 288.15;           % K
Pb(1) = 101325;           % Pa
for k = 1:numel(L)
    Tb(k+1) = Tb(k) + L(k)*(hb(k+1)-hb(k));
    if L(k) == 0
        Pb(k+1) = Pb(k) * exp(-g0*(hb(k+1)-hb(k))/(R*Tb(k)));
    else
        Pb(k+1) = Pb(k) * (Tb(k+1)/Tb(k))^(-g0/(R*L(k)));
    end
end

% Ensure altitude is non-negative
h = max(0, h);

% Preallocate outputs
T = zeros(size(h));
P = zeros(size(h));

% Determine properties per altitude
for j = 1:numel(h)
    hj = h(j);
    if hj >= hb(end)
        % Above highest defined layer: assume isothermal
        T(j) = Tb(end);
        P(j) = Pb(end) * exp(-g0*(hj - hb(end))/(R*Tb(end)));
    else
        i = find(hb <= hj, 1, 'last');
        Lk = L(i);
        Tk = Tb(i);
        Pk = Pb(i);
        if Lk == 0
            T(j) = Tk;
            P(j) = Pk * exp(-g0*(hj - hb(i))/(R*Tk));
        else
            T(j) = Tk + Lk*(hj - hb(i));
            P(j) = Pk * (T(j)/Tk)^(-g0/(R*Lk));
        end
    end
end

rho = P ./ (R*T);
a   = sqrt(gamma * R .* T);

end

