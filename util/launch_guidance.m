function [ufun,meta] = launch_guidance(mission,traj_params,init)
%LAUNCH_GUIDANCE Select historical or generalized initial guidance.
%
% Historical/default ground launch keeps the original vertical -> kick ->
% gravity-turn law. Inclined/air launches hold the requested initial
% flight-path direction for an optional time, then align thrust with
% velocity.

if init.is_historical_ground_default
    req={'t_pitch','pitch_kick','kick_dur'};
    for i=1:numel(req)
        if ~isfield(traj_params,req{i})
            error('launch_guidance:MissingHistoricalParameter', ...
                'Trajectory parameters require %s.',req{i});
        end
    end
    p=struct('t_pitch',traj_params.t_pitch, ...
        'kick_dur',traj_params.kick_dur, ...
        'kick_ang',traj_params.pitch_kick);
    ufun=guidance_profiles('vertical-then-kick-then-gravity-turn',p);
    meta.profile='vertical-then-kick-then-gravity-turn';
    meta.hold_duration_s=NaN;
else
    if isfield(traj_params,'initial_angle_hold_s')
        hold=traj_params.initial_angle_hold_s;
    elseif init.relative_speed_m_s < 10
        % A zero/very-low-speed inclined launch needs a finite initial
        % steering hold; otherwise velocity-aligned guidance would follow
        % Earth rotation (horizontal) or the zero-speed fallback instead
        % of the requested flight-path angle.
        hold=1;
    else
        hold=0;
    end
    validateattributes(hold,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    p=struct('initial_gamma_rad',init.flight_path_angle_rad, ...
        'hold_duration_s',hold);
    ufun=guidance_profiles('initial-angle-then-gravity-turn',p);
    meta.profile='initial-angle-then-gravity-turn';
    meta.hold_duration_s=hold;
end
meta.initial_mode=init.mode;
meta.initial_gamma_rad=init.flight_path_angle_rad;
end
