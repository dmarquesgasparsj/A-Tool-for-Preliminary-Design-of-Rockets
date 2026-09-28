function schedule = remaining_propulsion_schedule(traj_cfg,atmospheric_phase)
%REMAINING_PROPULSION_SCHEDULE Build serial propulsion after Kn transition.
%
% The first schedule segment is the unburned part of the active stage.
% Subsequent serial stages use their full propellant loads. At each stage
% boundary the spent dry mass is dropped, except after the final stage.
%
% Output fields per segment:
%   stage_index, name, thrust_N, Isp_s, mdot_kg_s,
%   propellant_kg, duration_s, dry_mass_drop_after_kg

if ~isfield(atmospheric_phase,'transition') || ...
        ~atmospheric_phase.transition.detected
    error('remaining_propulsion_schedule:NoTransition', ...
        'An atmospheric phase with a detected Knudsen transition is required.');
end
i0=atmospheric_phase.transition.stage_index;
N=numel(traj_cfg.stages);
if i0<1 || i0>N
    error('remaining_propulsion_schedule:StageIndex', ...
        'Invalid active stage index at transition.');
end
env=earth_constants();

template=struct('stage_index',0,'name','', ...
    'thrust_N',0,'Isp_s',0,'mdot_kg_s',0, ...
    'propellant_kg',0,'duration_s',0, ...
    'dry_mass_drop_after_kg',0);
schedule=repmat(template,1,N-i0+1);

for j=i0:N
    k=j-i0+1;
    st=traj_cfg.stages(j);
    mdot=st.thrust_N/(st.Isp_s*env.g0);
    if j==i0
        mp=atmospheric_phase.transition.remaining_propellant_kg;
    else
        mp=st.mp_kg;
    end
    if j<N
        dry_drop=st.ms_kg;
    else
        dry_drop=0;
    end

    schedule(k).stage_index=j;
    schedule(k).name=st.name;
    schedule(k).thrust_N=st.thrust_N;
    schedule(k).Isp_s=st.Isp_s;
    schedule(k).mdot_kg_s=mdot;
    schedule(k).propellant_kg=mp;
    schedule(k).duration_s=mp/mdot;
    schedule(k).dry_mass_drop_after_kg=dry_drop;
end
end
