function [rho, a, T, P] = atmosphere(h)
% ATMOSPHERE — Modelo ISA simples (exponencial) para densidade.
% Entradas:
%   h  — altitude acima do nível do mar [m]
% Saídas:
%   rho — densidade [kg/m^3]
%   a   — velocidade do som [m/s] (aprox. constante a 340 m/s ao nível do mar,
%          mas aqui aplicamos uma simplificação linear tosca)
%   T   — temperatura [K] (placeholder)
%   P   — pressão [Pa] (placeholder)
%
% Nota: Para projeto preliminar, a densidade exponencial é razoável. Ajusta H se necessário.

rho0 = 1.225;        % kg/m^3
H    = 8500.0;       % m — altura de escala típica
h = max(0, h);

rho = rho0 * exp(-h / H);

% Aproximações grosseiras para T, a, P (não usadas no núcleo do modelo)
T0 = 288.15;      % K
T  = max(170, T0 - 0.0065*h);  % corta aos ~170K
gamma = 1.4; R = 287.05;
a  = sqrt(gamma*R*T);
P  = rho*R*T;
end
