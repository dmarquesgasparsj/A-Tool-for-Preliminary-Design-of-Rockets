function result = simulate_parallel_booster_trajectory(cfg,sizing,opts)
%SIMULATE_PARALLEL_BOOSTER_TRAJECTORY Couple boosters to Kn=5 + TPBVP ascent.
%
% Runs the generalized booster sizing through the historical three-phase
% trajectory reconstruction by means of parallel_booster_trajectory_config.
% Optional Future-Work trajectory constraints are evaluated on the
% atmospheric phase.
%
% opts:
%   trajectory_config   options passed to parallel_booster_trajectory_config
%   atmospheric_opts
%   free_flight_opts
%   constraint_limits
%   constraint_opts

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'trajectory_config'), opts.trajectory_config=struct(); end
if ~isfield(opts,'atmospheric_opts'), opts.atmospheric_opts=struct(); end
if ~isfield(opts,'free_flight_opts'), opts.free_flight_opts=struct(); end
if ~isfield(opts,'constraint_limits'), opts.constraint_limits=struct(); end
if ~isfield(opts,'constraint_opts'), opts.constraint_opts=struct(); end

hcfg=parallel_booster_trajectory_config(cfg,sizing,opts.trajectory_config);
ref_opts=struct('atmospheric_opts',opts.atmospheric_opts, ...
    'free_flight_opts',opts.free_flight_opts);
traj=simulate_thesis_reference_trajectory(hcfg,ref_opts);

result=traj;
result.configuration=hcfg;
result.sizing=sizing;
result.mass_closure_error_kg=hcfg.mass_closure_error_kg;
result.constraints=evaluate_trajectory_constraints( ...
    traj.atmospheric,hcfg,opts.constraint_limits,opts.constraint_opts);
result.constraints_pass=result.constraints.all_pass;
result.model_status=[ ...
    'Generalized parallel boosters coupled to the reconstructed ', ...
    'atmospheric Kn=5 and staged TPBVP trajectory through a virtual ', ...
    'zeroth-stage flight segment.'];
end
