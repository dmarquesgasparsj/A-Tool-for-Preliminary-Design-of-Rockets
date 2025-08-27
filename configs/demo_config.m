function cfg = demo_config()
% DEMO_CONFIG — Configuração exemplo (2 estágios) para testes iniciais.
% Substitui pelos dados reais do teu veículo (Isp, empuxo, massas, CdA).
%
% Estrutura:
% cfg.stages(i) com campos:
%   .name       — identificador
%   .Isp_s      — impulso específico [s]
%   .thrust_N   — empuxo constante [N] durante a queima
%   .fs_struct  — fração estrutural (m_struct / (m_struct + m_prop))
%   .mp_kg      — massa de propelente [kg]
%   .CdA_m2     — coef. de arrasto x área de referência [m^2]
%
% NOTA: Para casos com 3-4 estágios, adicionar mais entradas ao vetor.

cfg.name = 'DEMO-2S';
cfg.notes = 'Modelo simplificado, sem boosters.';

% Estágio 1 (valores meramente ilustrativos)
s1.name      = 'Stage 1';
s1.Isp_s     = 280;          % s  (sólido ou líquido de baixa altitude)
s1.thrust_N  = 2.0e6;        % N
s1.fs_struct = 0.08;         % m_struct / (m_struct + m_prop)
s1.mp_kg     = 120e3;        % kg
s1.CdA_m2    = 4.0;          % m^2

% Estágio 2
s2.name      = 'Stage 2';
s2.Isp_s     = 330;          % s (líquido)
s2.thrust_N  = 600e3;        % N
s2.fs_struct = 0.10;         %
s2.mp_kg     = 30e3;         % kg
s2.CdA_m2    = 2.0;          % m^2

cfg.stages = [s1, s2];
end
