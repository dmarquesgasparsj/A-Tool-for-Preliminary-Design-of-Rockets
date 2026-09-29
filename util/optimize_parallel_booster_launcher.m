function result = optimize_parallel_booster_launcher(base_cfg,space,opts)
%OPTIMIZE_PARALLEL_BOOSTER_LAUNCHER Exhaustive, toolbox-free grid search.
%
% The optimizer is intentionally generic and deterministic. It evaluates
% user-supplied discrete values rather than hiding assumptions in a solver.
%
% Optional SPACE fields:
%   core_thrust_N
%   upper_thrust_N                 (first upper stage)
%   booster_thrust_N_each
%   booster_count
%   booster_burn_fraction_of_core
%   core_diameter_m
%   booster_diameter_m
%   delta_v_fractions              rows, each summing to one
%
% Missing fields default to BASE_CFG. A candidate is "feasible" only when
% size_parallel_booster_launcher() matches the allocated booster-phase
% Delta-V within opts.delta_v_match_tolerance_m_s and satisfies lift-off
% T/W. The best feasible candidate minimizes GLOW. The closest Delta-V
% candidate is also returned even when no feasible point exists.
%
% Diameter is carried through the configuration but the current MER model
% does not yet include vehicle skin/interstage geometry. Consequently a
% diameter sweep may be performance-neutral in the mass objective; this is
% reported, not hidden.

if nargin<2 || isempty(space), space=struct(); end
if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'delta_v_match_tolerance_m_s')
    opts.delta_v_match_tolerance_m_s=50;
end
if ~isfield(opts,'minimum_liftoff_TW'), opts.minimum_liftoff_TW=1.2; end
if ~isfield(opts,'max_evaluations'), opts.max_evaluations=50000; end

coreT=getv(space,'core_thrust_N',base_cfg.stages(1).thrust_N);
upperT=getv(space,'upper_thrust_N',base_cfg.stages(2).thrust_N);
boosterT=getv(space,'booster_thrust_N_each', ...
    base_cfg.boosters.stage.thrust_N);
counts=getv(space,'booster_count',base_cfg.boosters.count);
burns=getv(space,'booster_burn_fraction_of_core', ...
    base_cfg.boosters.burn_fraction_of_core);
coreD=getv(space,'core_diameter_m',base_cfg.stages(1).diameter_m);
boosterD=getv(space,'booster_diameter_m', ...
    base_cfg.boosters.stage.diameter_m);
if isfield(space,'delta_v_fractions') && ~isempty(space.delta_v_fractions)
    dvsets=space.delta_v_fractions;
else
    dvsets=base_cfg.parallel_delta_v_fractions;
end
if isvector(dvsets), dvsets=reshape(dvsets,1,[]); end
if size(dvsets,2)~=numel(base_cfg.parallel_delta_v_fractions)
    error('optimize_parallel_booster_launcher:DeltaVShape', ...
        'Each delta_v_fractions row must match the base segment count.');
end

n_eval=numel(coreT)*numel(upperT)*numel(boosterT)*numel(counts)* ...
    numel(burns)*numel(coreD)*numel(boosterD)*size(dvsets,1);
if n_eval>opts.max_evaluations
    error('optimize_parallel_booster_launcher:TooManyEvaluations', ...
        'Requested %d evaluations exceeds max_evaluations=%d.', ...
        n_eval,opts.max_evaluations);
end

blank=struct('success',false,'feasible',false,'GLOW_kg',Inf, ...
    'delta_v_error_m_s',Inf,'liftoff_TW',NaN,'message','', ...
    'core_thrust_N',NaN,'upper_thrust_N',NaN, ...
    'booster_thrust_N_each',NaN,'booster_count',NaN, ...
    'booster_burn_fraction_of_core',NaN,'core_diameter_m',NaN, ...
    'booster_diameter_m',NaN,'delta_v_fractions',[], ...
    'sizing',[]);
evaluations=repmat(blank,1,n_eval);
q=0;

for a=1:numel(coreT)
for b=1:numel(upperT)
for c=1:numel(boosterT)
for d=1:numel(counts)
for e=1:numel(burns)
for f=1:numel(coreD)
for g=1:numel(boosterD)
for h=1:size(dvsets,1)
    q=q+1;
    cand=base_cfg;
    cand.stages(1).thrust_N=coreT(a);
    cand.stages(1).diameter_m=coreD(f);
    cand.stages(2).thrust_N=upperT(b);
    cand.boosters.stage.thrust_N=boosterT(c);
    cand.boosters.stage.diameter_m=boosterD(g);
    cand.boosters.count=counts(d);
    cand.boosters.burn_fraction_of_core=burns(e);
    cand.parallel_delta_v_fractions=dvsets(h,:);

    ev=blank;
    ev.core_thrust_N=coreT(a);
    ev.upper_thrust_N=upperT(b);
    ev.booster_thrust_N_each=boosterT(c);
    ev.booster_count=counts(d);
    ev.booster_burn_fraction_of_core=burns(e);
    ev.core_diameter_m=coreD(f);
    ev.booster_diameter_m=boosterD(g);
    ev.delta_v_fractions=dvsets(h,:);
    try
        sizing=size_parallel_booster_launcher(cand,struct( ...
            'delta_v_match_tolerance_m_s', ...
                opts.delta_v_match_tolerance_m_s, ...
            'minimum_liftoff_TW',opts.minimum_liftoff_TW));
        ev.success=true;
        ev.feasible=sizing.feasible;
        ev.GLOW_kg=sizing.GLOW_kg;
        ev.delta_v_error_m_s=sizing.booster_phase_delta_v_error_m_s;
        ev.liftoff_TW=sizing.liftoff_TW;
        ev.message='ok';
        ev.sizing=sizing;
    catch ME
        ev.message=[ME.identifier ': ' ME.message];
    end
    evaluations(q)=ev;
end
end
end
end
end
end
end
end

success=[evaluations.success];
feasible=[evaluations.feasible];
best_feasible=[];
if any(feasible)
    idx=find(feasible);
    [~,j]=min([evaluations(idx).GLOW_kg]);
    best_feasible=evaluations(idx(j));
end

closest=[];
if any(success)
    idx=find(success);
    metric=abs([evaluations(idx).delta_v_error_m_s]);
    [~,j]=min(metric);
    closest=evaluations(idx(j));
end

result.evaluations=evaluations;
result.evaluation_count=n_eval;
result.success_count=nnz(success);
result.feasible_count=nnz(feasible);
result.best_feasible=best_feasible;
result.closest_delta_v=closest;
result.diameter_mass_model_warning=[ ...
    'Current MER sizing does not include skin/interstage geometry, so ', ...
    'diameter is not yet guaranteed to affect GLOW.'];
result.model_status=[ ...
    'Toolbox-free discrete optimizer for generalized parallel booster ', ...
    'configurations; no hidden interpolation or AI-generated search points.'];
end

function v=getv(space,name,default)
if isfield(space,name) && ~isempty(space.(name))
    v=space.(name);
else
    v=default;
end
v=reshape(v,1,[]);
end
