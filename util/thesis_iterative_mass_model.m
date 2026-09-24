function result = thesis_iterative_mass_model(cfg,opts)
%THESIS_ITERATIVE_MASS_MODEL Generalized modern multistage mass sizing.
%
% Solve any number of serial stages from upper to lower. Each stage's
% epsilon is solved by a bracketed bisection so that the structural mass
% from the rocket equation agrees with the propulsion-aware MER sum.
%
% This is a MODERN IMPROVEMENT to the recovered 2014 prototype's coarse
% epsilon grid. Default structural-mass relative tolerance: 0.1%.
%
% Required CFG: output of make_launcher_config(), or an equivalent struct.
% Propellant reserve, parallel boosters, ascent/Delta-V feedback and
% structural skin/interstages are not modeled in this function.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'tolerance'), opts.tolerance=1e-3; end
if ~isfield(opts,'max_iterations'), opts.max_iterations=90; end
validateattributes(opts.tolerance,{'numeric'}, ...
    {'scalar','real','finite','positive','<',1});
validateattributes(opts.max_iterations,{'numeric'}, ...
    {'scalar','integer','positive','finite'});
if ~isstruct(cfg) || ~isfield(cfg,'mission') || ...
        ~isfield(cfg,'stages') || isempty(cfg.stages)
    error('thesis_iterative_mass_model:InvalidConfig', ...
        'Provide a configuration from make_launcher_config().');
end
mission=cfg.mission;
if isfield(mission,'g0'), g0=mission.g0; else, g0=9.80665; end
validateattributes(g0,{'numeric'}, ...
    {'scalar','real','finite','positive'});
payload=mission.payload_kg;
total_dv=mission.delta_v_budget_m_s;
validateattributes(payload,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(total_dv,{'numeric'}, ...
    {'scalar','real','finite','positive'});

stages=cfg.stages;
fractions=[stages.delta_v_fraction];
if any(~isfinite(fractions)) || any(fractions<=0) || ...
        abs(sum(fractions)-1)>1e-8
    error('thesis_iterative_mass_model:DeltaVFractions', ...
        'Positive stage Delta-V fractions must sum to one.');
end

N=numel(stages);
blank=struct('name','','propulsion_type','','propellant_name','', ...
    'payload_above_kg',0,'delta_v_ms',0,'Isp_s',0,'epsilon',0, ...
    'k',0,'ms_kg',0,'mp_kg',0,'stage_wet_mass_kg',0, ...
    'section_initial_mass_kg',0,'mer',struct(),'iterations',0, ...
    'relative_structural_error',0,'history',zeros(0,5));
out=repmat(blank,1,N);
mass_above=payload;

for i=N:-1:1
    stage=stages(i);
    dv=total_dv*stage.delta_v_fraction;
    [ms,mp,k,epsilon,mer,history]=solve_stage( ...
        stage,mass_above,dv,g0,opts.tolerance,opts.max_iterations);

    out(i).name=stage.name;
    out(i).propulsion_type=stage.propulsion_type;
    out(i).propellant_name=stage.propellant_name;
    out(i).payload_above_kg=mass_above;
    out(i).delta_v_ms=dv;
    out(i).Isp_s=stage.Isp_s;
    out(i).epsilon=epsilon;
    out(i).k=k;
    out(i).ms_kg=ms;
    out(i).mp_kg=mp;
    out(i).stage_wet_mass_kg=ms+mp;
    out(i).section_initial_mass_kg=mass_above+ms+mp;
    out(i).mer=mer;
    out(i).iterations=size(history,1);
    out(i).relative_structural_error= ...
        abs(ms-mer.total_kg)/mer.total_kg;
    out(i).history=history;

    mass_above=mass_above+ms+mp;
end

result.stages=out;
result.GLOW_kg=mass_above;
result.payload_kg=payload;
result.payload_ratio=payload/mass_above;
result.total_delta_v_ms=total_dv;
result.delta_v_fractions=fractions;
result.converged=all([out.relative_structural_error]<=opts.tolerance);
result.tolerance=opts.tolerance;
result.status=['Modern serial-stage MER mass sizing; trajectory coupling, ', ...
    'parallel boosters, full geometry and mass margins are future work.'];
end

function [ms,mp,k,epsilon,mer,history]=solve_stage( ...
    stage,mass_above,dv,g0,tolerance,max_iterations)
k=exp(dv/(g0*stage.Isp_s));
if ~isfinite(k) || k<=1
    error('thesis_iterative_mass_model:InvalidStage', ...
        'Stage %s has an invalid mass ratio.',stage.name);
end

% k*epsilon < 1 is the exact feasibility condition.
left=0;
right=(1-1e-9)/k;
[f_left,~,~,~]=residual(left);
[f_right,~,~,~]=residual(right);
if ~isfinite(f_left) || ~isfinite(f_right) || ...
        f_left>=0 || f_right<=0
    error('thesis_iterative_mass_model:NoStructuralSolution', ...
        ['No bracketed structural-mass solution for %s. ', ...
         'Review Delta-V, Isp, thrust and MER assumptions.'],stage.name);
end

history=zeros(max_iterations,5);
for it=1:max_iterations
    epsilon=(left+right)/2;
    [f,ms,mp,mer]=residual(epsilon);
    relative=abs(f)/mer.total_kg;
    history(it,:)=[it,epsilon,ms,mer.total_kg,relative];
    if relative<=tolerance
        history=history(1:it,:);
        return;
    end
    if f>0
        right=epsilon;
    else
        left=epsilon;
    end
end
error('thesis_iterative_mass_model:NonConvergence', ...
    'Structural factor failed to converge in %d iterations for %s.', ...
    max_iterations,stage.name);

    function [f,ms_here,mp_here,mer_here]=residual(eps_here)
        [ms_here,mp_here]=thesis_stage_mass( ...
            mass_above,dv,stage.Isp_s,eps_here,g0);
        mer_here=modern_stage_mer(stage,ms_here,mp_here);
        f=ms_here-mer_here.total_kg;
    end
end
