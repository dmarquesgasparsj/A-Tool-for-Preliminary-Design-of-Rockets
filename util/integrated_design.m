function result = integrated_design(cfg, opts)
%INTEGRATED_DESIGN Couple generalized mass sizing with 2D ascent losses.
%
% This is the first modern implementation of the thesis-level feedback idea:
%   1) size the launcher for an estimated total Delta-V;
%   2) propagate the current simplified 2D trajectory;
%   3) compute drag and gravity losses;
%   4) update the total Delta-V estimate;
%   5) repeat until the Delta-V estimate changes by <= 0.01% by default.
%
% IMPORTANT: this modern feedback loop deliberately uses the generalized 2D
% ascent propagator. The separate thesis-reconstruction path implements the
% Kn=5 hand-off and staged TPBVP. Delta-V convergence and orbit attainment
% therefore remain separate diagnostics; neither is silently inferred.
%
% opts fields (all optional):
%   delta_v_tolerance       default 1e-4 (0.01%)
%   max_iterations          default 25
%   relaxation              default 0.5
%   min_liftoff_TW          default 1.2
%   default_Cd              default 0.5
%   launch_lat_deg          default mission value, otherwise 0
%   tol_v_ms                default 50
%   tol_gamma_deg           default 2
%   traj_params             default: t_pitch=20 s, kick=3 deg, 1 s
%   mass_opts               passed to thesis_iterative_mass_model
%
% The orbit ideal Delta-V is estimated as circular speed minus initial
% eastward rotational speed, plus integrated drag and gravity losses.

if nargin<2 || isempty(opts), opts=struct(); end
if ~isfield(opts,'delta_v_tolerance'), opts.delta_v_tolerance=1e-4; end
if ~isfield(opts,'max_iterations'), opts.max_iterations=25; end
if ~isfield(opts,'relaxation'), opts.relaxation=0.5; end
if ~isfield(opts,'min_liftoff_TW'), opts.min_liftoff_TW=1.2; end
if ~isfield(opts,'default_Cd'), opts.default_Cd=0.5; end
if ~isfield(opts,'tol_v_ms'), opts.tol_v_ms=50; end
if ~isfield(opts,'tol_gamma_deg'), opts.tol_gamma_deg=2; end
if ~isfield(opts,'mass_opts'), opts.mass_opts=struct(); end
if ~isfield(opts,'traj_params')
    opts.traj_params=struct('t_pitch',20, ...
        'pitch_kick',deg2rad(3),'kick_dur',1);
end

validateattributes(opts.delta_v_tolerance,{'numeric'}, ...
    {'scalar','real','finite','positive','<',1});
validateattributes(opts.max_iterations,{'numeric'}, ...
    {'scalar','integer','positive'});
validateattributes(opts.relaxation,{'numeric'}, ...
    {'scalar','real','finite','positive','<=',1});
validateattributes(opts.min_liftoff_TW,{'numeric'}, ...
    {'scalar','real','finite','positive'});

if ~isstruct(cfg) || ~isfield(cfg,'mission') || ...
        ~isfield(cfg,'stages') || isempty(cfg.stages)
    error('integrated_design:InvalidConfig', ...
        'Use make_launcher_config() or an equivalent generalized config.');
end
if ~isfield(cfg.mission,'orbit_altitude_km') || ...
        ~isfinite(cfg.mission.orbit_altitude_km)
    error('integrated_design:MissingOrbit', ...
        'A finite mission.orbit_altitude_km is required for coupling.');
end
if ~isfield(cfg.mission,'delta_v_budget_m_s')
    error('integrated_design:MissingDeltaV', ...
        'An initial mission.delta_v_budget_m_s estimate is required.');
end

env=earth_constants();
if isfield(opts,'launch_lat_deg')
    launch_lat_deg=opts.launch_lat_deg;
elseif isfield(cfg.mission,'launch_lat_deg') && ...
        isfinite(cfg.mission.launch_lat_deg)
    launch_lat_deg=cfg.mission.launch_lat_deg;
else
    launch_lat_deg=0;
end
validateattributes(launch_lat_deg,{'numeric'}, ...
    {'scalar','real','finite','>=',-90,'<=',90});

mission.target_alt=cfg.mission.orbit_altitude_km*1e3;
mission.launch_lat=deg2rad(launch_lat_deg);
mission.tol_v_ms=opts.tol_v_ms;
mission.tol_gamma=deg2rad(opts.tol_gamma_deg);

r_target=env.Re+mission.target_alt;
v_circular=sqrt(env.mu/r_target);
v_rotation=env.omega*env.Re*cos(mission.launch_lat);
ideal_delta_v=max(0,v_circular-v_rotation);

dv_budget=cfg.mission.delta_v_budget_m_s;
history=repmat(struct( ...
    'iteration',0,'delta_v_budget_m_s',0,'ideal_delta_v_m_s',0, ...
    'drag_loss_m_s',0,'gravity_loss_m_s',0, ...
    'required_delta_v_m_s',0,'relative_delta_v_error',0, ...
    'GLOW_kg',0,'liftoff_TW',0,'max_q_Pa',0, ...
    'orbit_reached',false),1,opts.max_iterations);

converged=false;
mass_result=[];
traj=[];
traj_cfg=[];
orbit=[];
liftoff_TW=NaN;

for it=1:opts.max_iterations
    cfg_it=cfg;
    cfg_it.mission.delta_v_budget_m_s=dv_budget;

    mass_result=thesis_iterative_mass_model(cfg_it,opts.mass_opts);
    traj_cfg=trajectory_config_from_mass_result(cfg_it,mass_result, ...
        struct('default_Cd',opts.default_Cd));

    liftoff_TW=traj_cfg.stages(1).thrust_N / ...
        (mass_result.GLOW_kg*env.g0);
    if liftoff_TW<=1
        error('integrated_design:NoLiftoff', ...
            ['First-stage thrust-to-weight is %.3f. The current design ', ...
             'cannot lift off.'],liftoff_TW);
    end

    traj=simulate_gravity_turn(traj_cfg,mission,opts.traj_params, ...
        cfg_it.mission.payload_kg);
    orbit=orbital_metrics(traj,mission);

    required_delta_v=ideal_delta_v + traj.losses.total_m_s;
    rel_err=abs(required_delta_v-dv_budget)/max(required_delta_v,eps);

    history(it).iteration=it;
    history(it).delta_v_budget_m_s=dv_budget;
    history(it).ideal_delta_v_m_s=ideal_delta_v;
    history(it).drag_loss_m_s=traj.losses.drag_m_s;
    history(it).gravity_loss_m_s=traj.losses.gravity_m_s;
    history(it).required_delta_v_m_s=required_delta_v;
    history(it).relative_delta_v_error=rel_err;
    history(it).GLOW_kg=mass_result.GLOW_kg;
    history(it).liftoff_TW=liftoff_TW;
    history(it).max_q_Pa=traj.max_dynamic_pressure_Pa;
    history(it).orbit_reached=orbit.reached;

    if rel_err<=opts.delta_v_tolerance
        converged=true;
        history=history(1:it);
        break;
    end

    dv_budget=(1-opts.relaxation)*dv_budget + ...
        opts.relaxation*required_delta_v;
end

if ~converged
    history=history(1:opts.max_iterations);
end

result.converged=converged;
result.delta_v_tolerance=opts.delta_v_tolerance;
result.iterations=numel(history);
result.history=history;
result.initial_delta_v_m_s=cfg.mission.delta_v_budget_m_s;
result.final_delta_v_budget_m_s=history(end).delta_v_budget_m_s;
result.required_delta_v_m_s=history(end).required_delta_v_m_s;
result.ideal_delta_v_m_s=ideal_delta_v;
result.drag_loss_m_s=history(end).drag_loss_m_s;
result.gravity_loss_m_s=history(end).gravity_loss_m_s;
result.mass=mass_result;
result.trajectory=traj;
result.trajectory_config=traj_cfg;
result.orbit=orbit;
result.liftoff_TW=liftoff_TW;
result.liftoff_margin_ok=liftoff_TW>=opts.min_liftoff_TW;
result.orbit_reached=orbit.reached;
result.fully_verified=result.converged && result.liftoff_margin_ok && ...
    result.orbit_reached;
result.model_status=[ ...
    'Generalized mass/trajectory Delta-V feedback using the modern 2D ', ...
    'propagator. Historical Kn=5/TPBVP validation and parallel-booster ', ...
    'trajectory paths are implemented separately to preserve provenance.'];
end
