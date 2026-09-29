function schedule = build_free_flight_schedule(stages,transition,opts)
%BUILD_FREE_FLIGHT_SCHEDULE Remaining serial propulsion after Kn transition.
%
% TRANSITION requires stage_index and remaining_propellant_kg. The active
% stage begins with only the propellant remaining at Kn transition; all
% later stages use their full documented/derived burn durations.
%
% opts.coast_time_s can be a scalar or N-1 vector. A coast is inserted
% after stage separation and before ignition of the next stage. This
% matches the Chapter 3 definition and allows the Chapter 6 historical
% validation cases to use their documented 3 s coast intervals.
%
% If the Kn transition itself occurs during a coast, TRANSITION may provide
% coast_remaining_s; that coast remainder is inserted before the next burn.

if nargin<3 || isempty(opts), opts=struct(); end
if ~isstruct(stages) || isempty(stages)
    error('build_free_flight_schedule:Stages','stages must be nonempty.');
end
if ~isfield(transition,'stage_index') || ...
        ~isfield(transition,'remaining_propellant_kg')
    error('build_free_flight_schedule:Transition', ...
        'transition requires stage_index and remaining_propellant_kg.');
end
N=numel(stages);
first=transition.stage_index;
validateattributes(first,{'numeric'}, ...
    {'scalar','integer','>=',1,'<=',N});
remaining=max(0,transition.remaining_propellant_kg);

coast=zeros(1,max(N-1,0));
if isfield(opts,'coast_time_s') && ~isempty(opts.coast_time_s)
    raw=opts.coast_time_s;
    validateattributes(raw,{'numeric'},{'vector','real','finite','nonnegative'});
    if isscalar(raw)
        coast(:)=raw;
    elseif numel(raw)==N-1
        coast=reshape(raw,1,[]);
    else
        error('build_free_flight_schedule:CoastSize', ...
            'coast_time_s must be scalar or contain N-1 values.');
    end
end

template=struct('name','','segment_type','burn','thrust_N',0, ...
    'mdot_kg_s',0,'duration_s',0,'dry_mass_drop_after_kg',0, ...
    'source_stage_index',0);
schedule=repmat(template,1,2*N+1);
out=0;

% Rare but well-defined case: the atmosphere boundary is crossed during
% the coast before FIRST stage in the returned schedule ignites.
if isfield(transition,'coast_remaining_s') && ...
        isfinite(transition.coast_remaining_s) && transition.coast_remaining_s>0
    out=out+1;
    schedule(out)=coast_segment(first,transition.coast_remaining_s);
end

for i=first:N
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
    if duration>0
        out=out+1;
        schedule(out).name=st.name;
        schedule(out).segment_type='burn';
        schedule(out).thrust_N=st.thrust_N;
        schedule(out).mdot_kg_s=mdot;
        schedule(out).duration_s=duration;
        schedule(out).source_stage_index=i;
        if i<N
            schedule(out).dry_mass_drop_after_kg=st.ms_kg;
        end
    end

    if i<N && coast(i)>0
        out=out+1;
        schedule(out)=coast_segment(i+1,coast(i));
    end
end

schedule=schedule(1:out);
if isempty(schedule) || ~any([schedule.mdot_kg_s]>0)
    error('build_free_flight_schedule:NoPropellant', ...
        'No propellant remains after the atmospheric transition.');
end

    function seg=coast_segment(next_stage,duration_s)
        seg=template;
        seg.name=sprintf('Coast before %s',stages(next_stage).name);
        seg.segment_type='coast';
        seg.thrust_N=0;
        seg.mdot_kg_s=0;
        seg.duration_s=duration_s;
        seg.dry_mass_drop_after_kg=0;
        seg.source_stage_index=next_stage;
    end
end
