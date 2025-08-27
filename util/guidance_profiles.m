function ufun = guidance_profiles(profile, params)
% GUIDANCE_PROFILES — devolve handle de função para orientação do empuxo.
% profile = 'vertical-then-kick-then-gravity-turn'
% params: struct com campos:
%   .t_pitch   — instante do *kick* [s]
%   .kick_dur  — duração do *kick* [s]
%   .kick_ang  — ângulo do *kick* (rad) em relação à vertical (radial)
%   Após o kick: thrust alinhado com a velocidade (gravity turn).

switch lower(profile)
    case 'vertical-then-kick-then-gravity-turn'
        tp   = params.t_pitch;
        tdur = params.kick_dur;
        ang  = params.kick_ang;
        ufun = @(t, state) local_fun(t, state, tp, tdur, ang);
    otherwise
        error('Perfil de guiamento desconhecido.');
end

end

function u = local_fun(t, state, tp, tdur, ang)
% Antes do tp: vertical pura (ur=1, utheta=0)
if t < tp
    u = [1; 0]; return;
end

% Durante a janela de *pitch kick*: direção fixa com inclinação 'ang'
if t >= tp && t < tp + tdur
    % vetor com ângulo em relação ao radial (vertical)
    ur   = cos(ang);
    uth  = sin(ang);
    u    = [ur; uth] / max(1e-9, hypot(ur, uth));
    return;
end

% Após kick: thrust alinhado com a velocidade (gravity turn)
vr     = state(3); vtheta = state(4);
vnorm  = hypot(vr, vtheta);
if vnorm < 1e-6
    u = [1; 0];
else
    u = [vr; vtheta] / vnorm;
end
end
