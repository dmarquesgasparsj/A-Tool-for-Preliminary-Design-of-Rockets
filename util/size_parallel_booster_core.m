function result = size_parallel_booster_core(upper_mass_kg,core_stage, ...
    booster_stage,target_core_only_delta_v_m_s,booster_count, ...
    booster_burn_fraction_of_core,opts)
%SIZE_PARALLEL_BOOSTER_CORE Size a booster-assisted core stage.
%
% Modern 2026 reconstruction inspired by the thesis parallel-staging model.
% The upper stack is assumed already sized. The core dry mass is solved by
% matching the Tsiolkovsky mass solution to modern_stage_mer(). The boosters
% burn for a specified fraction of the core burn time; their propellant mass
% follows thrust/(Isp*g0), and each booster dry mass is solved from its MER.
%
% The requested Delta-V applies to the core-only phase AFTER booster
% jettison. The parallel "zeroth-stage" Delta-V is an output determined by
% booster thrust, booster count and burn fraction.
%
% This avoids pretending that the lost 2014 booster mass solver has been
% recovered exactly. All new assumptions are explicit and testable.

if nargin<7 || isempty(opts), opts=struct(); end
if ~isfield(opts,'g0'), opts.g0=9.80665; end
if ~isfield(opts,'tolerance'), opts.tolerance=1e-3; end
if ~isfield(opts,'max_iterations'), opts.max_iterations=100; end
validateattributes(upper_mass_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(target_core_only_delta_v_m_s,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(booster_count,{'numeric'}, ...
    {'scalar','integer','positive'});
validateattributes(booster_burn_fraction_of_core,{'numeric'}, ...
    {'scalar','real','finite','>',0,'<',1});

g0=opts.g0;
ve_core=core_stage.Isp_s*g0;
k=exp(target_core_only_delta_v_m_s/ve_core);
f=booster_burn_fraction_of_core;

% Feasibility bound from:
% U + [epsilon + (1-f)(1-epsilon)] C
%   = k [U + epsilon C].
eps_feasible=(1-f)/(k-f);
if ~isfinite(eps_feasible) || eps_feasible<=0
    error('size_parallel_booster_core:InfeasibleCore', ...
        'No positive structural-factor range for the requested core Delta-V.');
end
upper_eps=min(0.5,0.999*eps_feasible);
if upper_eps<=1e-5
    error('size_parallel_booster_core:InfeasibleCore', ...
        'Requested core-only Delta-V leaves no feasible structural factor.');
end

scan=linspace(1e-5,upper_eps,250);
res=zeros(size(scan));
for j=1:numel(scan)
    [res(j),~,~,~]=core_residual(scan(j));
end
pair=find(res(1:end-1).*res(2:end)<=0,1,'first');
if isempty(pair)
    [best_abs,best_idx]=min(abs(res));
    error('size_parallel_booster_core:NoStructuralRoot', ...
        ['No MER/Tsiolkovsky structural root found. Best scanned residual ', ...
         'is %.3f kg at epsilon %.5f.'],best_abs,scan(best_idx));
end

lo=scan(pair);
hi=scan(pair+1);
history=zeros(opts.max_iterations,5);
for it=1:opts.max_iterations
    eps_core=(lo+hi)/2;
    [r,ms_core,mp_core,mer_core]=core_residual(eps_core);
    rel=abs(r)/max(mer_core.total_kg,eps);
    history(it,:)=[it,eps_core,ms_core,mer_core.total_kg,rel];
    if rel<=opts.tolerance
        history=history(1:it,:);
        break;
    end
    [rlo,~,~,~]=core_residual(lo);
    if rlo*r<=0
        hi=eps_core;
    else
        lo=eps_core;
    end
    if it==opts.max_iterations
        error('size_parallel_booster_core:CoreNonConvergence', ...
            'Core structural solution did not converge.');
    end
end

core_mdot=core_stage.thrust_N/(core_stage.Isp_s*g0);
core_burn_time=mp_core/core_mdot;
booster_burn_time=f*core_burn_time;
booster_mdot=booster_stage.thrust_N/(booster_stage.Isp_s*g0);
mp_booster_each=booster_mdot*booster_burn_time;

% Solve each solid booster dry mass from its MER. This intentionally sizes
% one booster and multiplies it, rather than applying nonlinear nozzle/
% avionics MERs to an aggregate booster pair.
ms_booster_each=solve_booster_ms(mp_booster_each);
booster_mer=modern_stage_mer(booster_stage, ...
    ms_booster_each,mp_booster_each);

core=core_stage;
core.mp_kg=mp_core;
core.ms_kg=ms_core;
core.burn_time_s=core_burn_time;

booster=booster_stage;
booster.count=booster_count;
booster.mp_kg=mp_booster_each;
booster.ms_kg=ms_booster_each;
booster.burn_time_s=booster_burn_time;

perf=parallel_booster_performance(upper_mass_kg,core,booster, ...
    struct('g0',g0));

result.upper_mass_kg=upper_mass_kg;
result.core=core;
result.core_mer=mer_core;
result.core_epsilon=eps_core;
result.core_history=history;
result.booster=booster;
result.booster_mer=booster_mer;
result.booster_count=booster_count;
result.booster_total_propellant_kg=booster_count*mp_booster_each;
result.booster_total_structural_kg=booster_count*ms_booster_each;
result.performance=perf;
result.GLOW_kg=perf.initial_mass_kg;
result.target_core_only_delta_v_m_s=target_core_only_delta_v_m_s;
result.actual_core_only_delta_v_m_s=perf.phase1_delta_v_m_s;
result.actual_booster_phase_delta_v_m_s=perf.phase0_delta_v_m_s;
result.liftoff_TW=perf.liftoff_TW;
result.model_status=[ ...
    'Modern MER-coupled core sizing plus per-booster solid MER sizing; ', ...
    'parallel phase evaluated with direct mass accounting.'];

    function [rr,ms,mp,mer]=core_residual(epsilon)
        coeff=epsilon+(1-f)*(1-epsilon);
        den=coeff-k*epsilon;
        if den<=0
            rr=NaN; ms=NaN; mp=NaN; mer=struct('total_kg',NaN);
            return;
        end
        wet=(k-1)*upper_mass_kg/den;
        ms=epsilon*wet;
        mp=(1-epsilon)*wet;
        mer=modern_stage_mer(core_stage,ms,mp);
        rr=ms-mer.total_kg;
    end

    function ms=solve_booster_ms(mp)
        lo_ms=0;
        hi_ms=max(0.25*mp,100);
        f_lo=booster_residual(lo_ms,mp);
        f_hi=booster_residual(hi_ms,mp);
        expansions=0;
        while f_hi<=0 && expansions<20
            hi_ms=2*hi_ms;
            f_hi=booster_residual(hi_ms,mp);
            expansions=expansions+1;
        end
        if f_lo>=0 || f_hi<=0
            error('size_parallel_booster_core:BoosterStructuralRoot', ...
                'Could not bracket booster structural MER solution.');
        end
        for kk=1:opts.max_iterations
            mid=(lo_ms+hi_ms)/2;
            fm=booster_residual(mid,mp);
            mer_mid=modern_stage_mer(booster_stage,mid,mp);
            if abs(fm)/max(mer_mid.total_kg,eps)<=opts.tolerance
                ms=mid;
                return;
            end
            if fm>0, hi_ms=mid; else, lo_ms=mid; end
        end
        error('size_parallel_booster_core:BoosterNonConvergence', ...
            'Booster structural MER solution did not converge.');
    end

    function rr=booster_residual(ms,mp)
        bmer=modern_stage_mer(booster_stage,ms,mp);
        rr=ms-bmer.total_kg;
    end
end
