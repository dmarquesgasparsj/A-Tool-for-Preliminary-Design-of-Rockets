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
    case 'initial-angle-then-gravity-turn'
        if ~isfield(params,'initial_gamma_rad')
            error('guidance_profiles:InitialGamma', ...
                'initial_gamma_rad is required.');
        end
        if ~isfield(params,'hold_duration_s'), params.hold_duration_s=0; end
        gamma0=params.initial_gamma_rad;
        hold=params.hold_duration_s;
        if isfield(params,'launch_lat'), lat=params.launch_lat; else, lat=0; end
        if isfield(params,'atmosphere_rotates')
            rotates=logical(params.atmosphere_rotates);
        else
            rotates=true;
        end
        ufun=@(t,state) inclined_fun(t,state,gamma0,hold,lat,rotates);
    case 'velocity-aligned'
        ufun=@(~,state) velocity_aligned(state);
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


function u = inclined_fun(t,state,gamma0,hold,lat,rotates)
if t < hold
    % gamma measured above local horizontal: [radial;tangential]
    u=[sin(gamma0);cos(gamma0)];
    u=u/max(norm(u),eps);
else
    env=earth_constants();
    env.launch_lat=lat;
    env.atmosphere_rotates=rotates;
    air=atmosphere_relative_velocity_2d( ...
        state(1),state(3),state(4),env);
    if air.speed_m_s<1e-8
        u=[sin(gamma0);cos(gamma0)];
    else
        u=[air.vr_m_s;air.vtheta_m_s]/air.speed_m_s;
    end
end
end

function u = velocity_aligned(state)
vr=state(3); vtheta=state(4);
vnorm=hypot(vr,vtheta);
if vnorm<1e-8
    u=[1;0];
else
    u=[vr;vtheta]/vnorm;
end
end
