function schedule = build_free_flight_schedule(stages,transition)
%BUILD_FREE_FLIGHT_SCHEDULE Remaining serial propulsion after Kn transition.
%
% TRANSITION requires stage_index and remaining_propellant_kg. The active
% stage begins with only the propellant remaining at Kn transition; all
% later stages use their full documented/derived burn durations.

if ~isstruct(stages) || isempty(stages)
    error('build_free_flight_schedule:Stages','stages must be nonempty.');
end
if ~isfield(transition,'stage_index') || ...
        ~isfield(transition,'remaining_propellant_kg')
    error('build_free_flight_schedule:Transition', ...
        'transition requires stage_index and remaining_propellant_kg.');
end
first=transition.stage_index;
validateattributes(first,{'numeric'},{'scalar','integer','>=',1,'<=',numel(stages)});
remaining=max(0,transition.remaining_propellant_kg);

template=struct('name','','thrust_N',0,'mdot_kg_s',0, ...
    'duration_s',0,'dry_mass_drop_after_kg',0,'source_stage_index',0);
schedule=repmat(template,1,numel(stages)-first+1);
out=0;
for i=first:numel(stages)
    st=stages(i);
    req={'name','thrust_N','mp_kg','ms_kg','burn_time_s'};
    for j=1:numel(req)
        if ~isfield(st,req{j})
            error('build_free_flight_schedule:StageField', ...
                'Stage %d lacks %s.',i,req{j});
        end
    end
    mdot=st.mp_kg/st.burn_time_s;
    if i==first
        prop=remaining;
    else
        prop=st.mp_kg;
    end
    duration=prop/mdot;
    if duration<=0
        continue;
    end
    out=out+1;
    schedule(out).name=st.name;
    schedule(out).thrust_N=st.thrust_N;
    schedule(out).mdot_kg_s=mdot;
    schedule(out).duration_s=duration;
    schedule(out).source_stage_index=i;
    if i<numel(stages)
        schedule(out).dry_mass_drop_after_kg=st.ms_kg;
    end
end
schedule=schedule(1:out);
if isempty(schedule)
    error('build_free_flight_schedule:NoPropellant', ...
        'No propellant remains after the atmospheric transition.');
end
end
