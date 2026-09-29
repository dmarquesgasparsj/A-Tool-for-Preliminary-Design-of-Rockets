function out = parallel_booster_performance(upper_mass_kg,core,booster,opts)
%PARALLEL_BOOSTER_PERFORMANCE Evaluate a core + parallel booster sequence.
%
% This implements the physical two-phase interpretation of the thesis
% "zeroth stage":
%   phase 0: core and N boosters burn simultaneously;
%   jettison: empty booster dry masses are discarded;
%   phase 1: the core continues alone until its burnout.
%
% Required CORE/BOOSTER fields:
%   mp_kg, ms_kg, thrust_N, Isp_s
% BOOSTER additionally requires count.
%
% Burn duration can be supplied explicitly as burn_time_s. Otherwise mass
% flow follows thrust/(Isp*g0). If only the core has a duration, booster
% burn_time_s must still be supplied or opts.booster_burn_fraction_of_core
% must be provided.
%
% The thesis ratios epsilon0/epsilon1 are returned for provenance, but the
% Delta-V calculation below uses direct mass accounting because the notation
% around m_ip1 in Eqs. 2.12-2.15 is internally ambiguous in the dissertation.

if nargin<4 || isempty(opts), opts=struct(); end
if ~isfield(opts,'g0'), opts.g0=9.80665; end
if ~isfield(opts,'booster_burn_fraction_of_core')
    opts.booster_burn_fraction_of_core=NaN;
end
validateattributes(upper_mass_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(opts.g0,{'numeric'}, ...
    {'scalar','real','finite','positive'});
for name={'core','booster'}
    s=eval(name{1}); %#ok<EVLDIR>
    req={'mp_kg','ms_kg','thrust_N','Isp_s'};
    for j=1:numel(req)
        if ~isfield(s,req{j})
            error('parallel_booster_performance:MissingField', ...
                '%s.%s is required.',name{1},req{j});
        end
    end
end
if ~isfield(booster,'count')
    error('parallel_booster_performance:MissingCount', ...
        'booster.count is required.');
end
validateattributes(booster.count,{'numeric'}, ...
    {'scalar','integer','positive','finite'});

g0=opts.g0;
core_mdot=mass_flow(core,g0);
booster_mdot_each=mass_flow(booster,g0);
core_tb=burn_time(core,core_mdot);

if isfield(booster,'burn_time_s') && ...
        isfinite(booster.burn_time_s) && booster.burn_time_s>0
    booster_tb=booster.burn_time_s;
elseif isfinite(opts.booster_burn_fraction_of_core)
    validateattributes(opts.booster_burn_fraction_of_core,{'numeric'}, ...
        {'scalar','real','finite','>',0,'<',1});
    booster_tb=opts.booster_burn_fraction_of_core*core_tb;
else
    booster_tb=booster.mp_kg/booster_mdot_each;
end
if booster_tb>=core_tb
    error('parallel_booster_performance:BurnDuration', ...
        'Booster burn must end before core burnout.');
end

core_prop_overlap=min(core.mp_kg,core_mdot*booster_tb);
booster_prop_each=min(booster.mp_kg,booster_mdot_each*booster_tb);
if abs(booster_prop_each-booster.mp_kg)>max(1e-6,1e-6*booster.mp_kg)
    error('parallel_booster_performance:BoosterPropellantMismatch', ...
        ['Booster burn duration and mass flow do not consume the supplied ', ...
         'booster propellant mass.']);
end

n=booster.count;
m0=upper_mass_kg+core.ms_kg+core.mp_kg + ...
    n*(booster.ms_kg+booster.mp_kg);
m_before_sep=m0-core_prop_overlap-n*booster.mp_kg;
m_after_sep=m_before_sep-n*booster.ms_kg;
core_prop_remaining=max(0,core.mp_kg-core_prop_overlap);
m_core_burnout=upper_mass_kg+core.ms_kg;

if m_before_sep<=0 || m_after_sep<=m_core_burnout
    error('parallel_booster_performance:MassAccounting', ...
        'Inconsistent masses for parallel staging.');
end

T0=core.thrust_N+n*booster.thrust_N;
mdot0=core_mdot+n*booster_mdot_each;
ve0=T0/mdot0;
ve1=core.thrust_N/core_mdot;

dv0=ve0*log(m0/m_before_sep);
dv1=ve1*log(m_after_sep/m_core_burnout);

out.initial_mass_kg=m0;
out.upper_mass_kg=upper_mass_kg;
out.phase0_delta_v_m_s=dv0;
out.phase1_delta_v_m_s=dv1;
out.total_delta_v_m_s=dv0+dv1;
out.mass_before_booster_jettison_kg=m_before_sep;
out.mass_after_booster_jettison_kg=m_after_sep;
out.core_burnout_mass_kg=m_core_burnout;
out.core_propellant_burned_with_boosters_kg=core_prop_overlap;
out.core_propellant_remaining_after_boosters_kg=core_prop_remaining;
out.booster_burn_time_s=booster_tb;
out.core_burn_time_s=core_tb;
out.booster_burn_fraction_of_core=booster_tb/core_tb;
out.liftoff_TW=T0/(m0*g0);
out.effective_exhaust_velocity_overlap_m_s=ve0;
out.core_exhaust_velocity_m_s=ve1;
out.core=core;
out.booster=booster;

% Thesis Eq. (2.12), using aggregate boosters as the "zeroth" stage.
out.thesis_epsilon0=(n*booster.ms_kg+core.ms_kg) / ...
    (n*(booster.ms_kg+booster.mp_kg)+core.ms_kg+core.mp_kg);

% Eq. (2.14) is returned literally using the thesis statement that m_ip1
% is core propellant remaining at booster burnout. It is diagnostic only.
mip1=core_prop_remaining;
den=core.ms_kg+(core.mp_kg-mip1);
if den>0
    out.thesis_epsilon1_literal=core.ms_kg/den;
else
    out.thesis_epsilon1_literal=NaN;
end
out.model_status=[ ...
    'Physical parallel-staging evaluator with thesis zeroth-stage ', ...
    'provenance diagnostics; no aerodynamic/trajectory losses included.'];
end

function mdot=mass_flow(stage,g0)
if isfield(stage,'mass_flow_kg_s') && ...
        isfinite(stage.mass_flow_kg_s) && stage.mass_flow_kg_s>0
    mdot=stage.mass_flow_kg_s;
elseif isfield(stage,'burn_time_s') && ...
        isfinite(stage.burn_time_s) && stage.burn_time_s>0
    mdot=stage.mp_kg/stage.burn_time_s;
else
    mdot=stage.thrust_N/(stage.Isp_s*g0);
end
validateattributes(mdot,{'numeric'}, ...
    {'scalar','real','finite','positive'});
end

function tb=burn_time(stage,mdot)
if isfield(stage,'burn_time_s') && ...
        isfinite(stage.burn_time_s) && stage.burn_time_s>0
    tb=stage.burn_time_s;
else
    tb=stage.mp_kg/mdot;
end
end
