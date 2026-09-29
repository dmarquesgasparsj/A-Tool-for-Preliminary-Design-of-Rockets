function result = thesis_mass_trajectory_feedback(cfg,opts)
%THESIS_MASS_TRAJECTORY_FEEDBACK Historical-style Delta-V feedback loop.
%
% Iterates:
%   generalized MER mass model
%   -> thesis-mode atmosphere/gravity turn
%   -> Knudsen transition
%   -> staged TPBVP
%   -> last-stage propellant residual
%   -> Tsiolkovsky Delta-V correction
% until the design Delta-V changes by <= 0.01% (default).
%
% This is a 2026 reconstruction of the Chapter 5 algorithm. It does not
% claim byte-for-byte identity with the lost final 2014 implementation.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'tolerance'), opts.tolerance=1e-4; end
if ~isfield(opts,'max_iterations'), opts.max_iterations=12; end
if ~isfield(opts,'relaxation'), opts.relaxation=1; end
if ~isfield(opts,'mass_opts'), opts.mass_opts=struct(); end
if ~isfield(opts,'trajectory_opts'), opts.trajectory_opts=struct(); end
validateattributes(opts.tolerance,{'numeric'}, ...
    {'scalar','real','finite','positive','<',1});
validateattributes(opts.max_iterations,{'numeric'}, ...
    {'scalar','integer','positive'});
validateattributes(opts.relaxation,{'numeric'}, ...
    {'scalar','real','finite','positive','<=',1});

dv=cfg.mission.delta_v_budget_m_s;
history=repmat(struct('iteration',0,'delta_v_in_m_s',0, ...
    'delta_v_correction_m_s',NaN,'delta_v_out_m_s',NaN, ...
    'relative_change',NaN,'GLOW_kg',NaN,'orbit_reached',false, ...
    'last_stage_residual_kg',NaN,'last_stage_residual_fraction',NaN, ...
    'trajectory_status',''),1,opts.max_iterations);

converged=false;
termination='maximum_iterations';
mass=[]; trajectory=[]; corrected_cfg=cfg;

for it=1:opts.max_iterations
    corrected_cfg=cfg;
    corrected_cfg.mission.delta_v_budget_m_s=dv;
    mass=thesis_iterative_mass_model(corrected_cfg,opts.mass_opts);
    trajectory=simulate_thesis_2014_trajectory( ...
        corrected_cfg,mass,opts.trajectory_opts);

    h=history(it);
    h.iteration=it;
    h.delta_v_in_m_s=dv;
    h.GLOW_kg=mass.GLOW_kg;
    h.orbit_reached=trajectory.orbit_reached;
    h.trajectory_status=trajectory.status;

    if isempty(trajectory.free_flight) || ~trajectory.orbit_reached
        history(it)=h;
        history=history(1:it);
        termination='trajectory_not_converged';
        break;
    end

    residual=trajectory.last_stage_propellant_remaining_kg;
    residual_fraction=trajectory.last_stage_propellant_remaining_fraction;
    last=mass.stages(end);
    corr=thesis_propellant_residual_delta_v(last, ...
        last.payload_above_kg,residual,corrected_cfg.mission.g0);
    proposed=max(eps,dv+corr.delta_v_correction_m_s);
    next_dv=(1-opts.relaxation)*dv+opts.relaxation*proposed;
    relative=abs(next_dv-dv)/max(dv,eps);

    h.delta_v_correction_m_s=corr.delta_v_correction_m_s;
    h.delta_v_out_m_s=next_dv;
    h.relative_change=relative;
    h.last_stage_residual_kg=residual;
    h.last_stage_residual_fraction=residual_fraction;
    history(it)=h;

    if relative<=opts.tolerance
        converged=true;
        history=history(1:it);
        termination='delta_v_converged';
        dv=next_dv;
        break;
    end
    dv=next_dv;
end

if numel(history)>opts.max_iterations
    history=history(1:opts.max_iterations);
end

result.converged=converged;
result.termination=termination;
result.iterations=numel(history);
result.history=history;
result.initial_delta_v_m_s=cfg.mission.delta_v_budget_m_s;
result.final_delta_v_m_s=dv;
result.mass=mass;
result.trajectory=trajectory;
result.configuration=corrected_cfg;
result.tolerance=opts.tolerance;
result.model_status=[ ...
    'Chapter-5-style mass/trajectory feedback using last-stage residual ', ...
    'propellant and Tsiolkovsky; modern reconstruction, not recovered final source.'];
end
