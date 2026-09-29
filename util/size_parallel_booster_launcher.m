function result = size_parallel_booster_launcher(cfg,opts)
%SIZE_PARALLEL_BOOSTER_LAUNCHER Size one booster-assisted core + upper stages.
%
% Configuration:
%   cfg.mission.payload_kg
%   cfg.mission.delta_v_budget_m_s
%   cfg.stages(1)              core stage
%   cfg.stages(2:end)          serial upper stages
%   cfg.boosters.count
%   cfg.boosters.burn_fraction_of_core
%   cfg.boosters.stage         one physical booster specification
%   cfg.parallel_delta_v_fractions =
%       [booster_parallel, core_only, upper_stage_1, ...]
%
% Fractions must sum to one. Upper stages are sized with the existing
% generalized MER solver. The core/booster pair is then sized with
% size_parallel_booster_core(). Booster-phase Delta-V is *predicted* from
% thrust/count/burn fraction and compared with its allocated target.
%
% This architecture generalizes the thesis "zeroth stage" without requiring
% a separate 2/3/4-stage code path.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'g0'), opts.g0=9.80665; end
if ~isfield(opts,'delta_v_match_tolerance_m_s')
    opts.delta_v_match_tolerance_m_s=50;
end
if ~isfield(opts,'minimum_liftoff_TW'), opts.minimum_liftoff_TW=1.2; end
if ~isfield(opts,'mass_opts'), opts.mass_opts=struct(); end

required={'mission','stages','boosters','parallel_delta_v_fractions'};
for i=1:numel(required)
    if ~isfield(cfg,required{i})
        error('size_parallel_booster_launcher:MissingField', ...
            'cfg.%s is required.',required{i});
    end
end
if numel(cfg.stages)<2
    error('size_parallel_booster_launcher:StageCount', ...
        'At least one core and one upper stage are required.');
end
if ~isfield(cfg.boosters,'stage') || ...
        ~isfield(cfg.boosters,'count') || ...
        ~isfield(cfg.boosters,'burn_fraction_of_core')
    error('size_parallel_booster_launcher:Boosters', ...
        'boosters requires stage, count and burn_fraction_of_core.');
end

fractions=reshape(cfg.parallel_delta_v_fractions,1,[]);
N=numel(cfg.stages);
if numel(fractions)~=N+1
    error('size_parallel_booster_launcher:DeltaVSegments', ...
        ['parallel_delta_v_fractions must contain booster phase, ', ...
         'core-only phase and one value per upper stage.']);
end
if any(~isfinite(fractions)) || any(fractions<=0) || ...
        abs(sum(fractions)-1)>1e-8
    error('size_parallel_booster_launcher:DeltaVFractions', ...
        'Positive segment Delta-V fractions must sum to one.');
end

mission=cfg.mission;
if ~isfield(mission,'g0'), mission.g0=opts.g0; end
total_dv=mission.delta_v_budget_m_s;
upper_fractions=fractions(3:end);
upper_total_fraction=sum(upper_fractions);

upper_cfg.mission=mission;
upper_cfg.mission.delta_v_budget_m_s=total_dv*upper_total_fraction;
upper_cfg.stages=cfg.stages(2:end);
for i=1:numel(upper_cfg.stages)
    upper_cfg.stages(i).delta_v_fraction= ...
        upper_fractions(i)/upper_total_fraction;
end
upper_cfg.source='Upper stack extracted from parallel-booster configuration';
upper=thesis_iterative_mass_model(upper_cfg,opts.mass_opts);
upper_mass=upper.GLOW_kg;

core_target_dv=total_dv*fractions(2);
lower=size_parallel_booster_core(upper_mass,cfg.stages(1), ...
    cfg.boosters.stage,core_target_dv,cfg.boosters.count, ...
    cfg.boosters.burn_fraction_of_core, ...
    struct('g0',mission.g0));

target_booster_dv=total_dv*fractions(1);
actual_booster_dv=lower.actual_booster_phase_delta_v_m_s;
booster_dv_error=actual_booster_dv-target_booster_dv;
upper_dv=upper_cfg.mission.delta_v_budget_m_s;
actual_total=actual_booster_dv+ ...
    lower.actual_core_only_delta_v_m_s+upper_dv;

result.upper=upper;
result.lower=lower;
result.GLOW_kg=lower.GLOW_kg;
result.payload_kg=mission.payload_kg;
result.payload_ratio=mission.payload_kg/result.GLOW_kg;
result.target_total_delta_v_m_s=total_dv;
result.actual_ideal_total_delta_v_m_s=actual_total;
result.parallel_delta_v_fractions=fractions;
result.target_booster_phase_delta_v_m_s=target_booster_dv;
result.actual_booster_phase_delta_v_m_s=actual_booster_dv;
result.booster_phase_delta_v_error_m_s=booster_dv_error;
result.target_core_only_delta_v_m_s=core_target_dv;
result.upper_delta_v_m_s=upper_dv;
result.liftoff_TW=lower.liftoff_TW;
result.delta_v_match=abs(booster_dv_error)<= ...
    opts.delta_v_match_tolerance_m_s;
result.liftoff_ok=result.liftoff_TW>=opts.minimum_liftoff_TW;
result.feasible=result.delta_v_match && result.liftoff_ok;
result.model_status=[ ...
    'Modern generalized parallel-booster mass sizing. Feasibility checks ', ...
    'ideal Delta-V allocation and liftoff T/W; trajectory losses are not ', ...
    'yet coupled inside this sizing function.'];
end
