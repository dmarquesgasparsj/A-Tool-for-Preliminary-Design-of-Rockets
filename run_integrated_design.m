function [result,cfg] = run_integrated_design(mission,stage_specs,opts)
%RUN_INTEGRATED_DESIGN User-facing mass + trajectory Delta-V coupling.
%
% Interactive:
%   result = run_integrated_design();
%
% Programmatic:
%   result = run_integrated_design(mission,stage_specs);
%   result = run_integrated_design(cfg);
%
% This runner uses the modern coupled 2D ascent model. Historical Kn=5 and
% staged-TPBVP reconstruction is available through dedicated validation APIs.

root=fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));

if nargin<3 || isempty(opts), opts=struct(); end
interactive=(nargin==0 || isempty(mission));

if interactive
    cfg=launcher_menu();
    if isempty(cfg)
        result=[];
        return;
    end
    if ~isfield(opts,'show_plots'), opts.show_plots=true; end
elseif nargin<2 || isempty(stage_specs)
    cfg=mission;
else
    cfg=make_launcher_config(mission,stage_specs);
end
if ~isfield(opts,'show_plots'), opts.show_plots=false; end

solver_opts=opts;
if isfield(solver_opts,'show_plots')
    solver_opts=rmfield(solver_opts,'show_plots');
end
result=integrated_design(cfg,solver_opts);
result.configuration=cfg;

fprintf('\n=== Integrated preliminary launcher design ===\n');
fprintf('Payload: %.2f kg | Target orbit: %.1f km\n', ...
    cfg.mission.payload_kg,cfg.mission.orbit_altitude_km);
fprintf('Delta-V: initial %.1f -> required %.1f m/s\n', ...
    result.initial_delta_v_m_s,result.required_delta_v_m_s);
fprintf('Losses: drag %.1f + gravity %.1f = %.1f m/s\n', ...
    result.drag_loss_m_s,result.gravity_loss_m_s, ...
    result.drag_loss_m_s+result.gravity_loss_m_s);
fprintf('Iterations: %d | Delta-V converged: %s\n', ...
    result.iterations,logical_text(result.converged));
fprintf('GLOW: %.1f kg | Lift-off T/W: %.3f (>= 1.2: %s)\n', ...
    result.mass.GLOW_kg,result.liftoff_TW, ...
    logical_text(result.liftoff_margin_ok));
fprintf('Max dynamic pressure: %.1f kPa\n', ...
    result.trajectory.max_dynamic_pressure_Pa/1000);
fprintf('Current trajectory reaches requested circular-orbit tolerance: %s\n', ...
    logical_text(result.orbit_reached));
if ~result.orbit_reached
    fprintf(['Trajectory status: NOT orbit-validated. Restore the thesis ', ...
        'three-phase validation path for historical reconstruction diagnostics.\n']);
end

if opts.show_plots
    plot_trajectory(result.trajectory);
    figure('Name','Integrated design convergence');
    semilogy([result.history.iteration], ...
        [result.history.relative_delta_v_error],'-o');
    xlabel('Coupling iteration');
    ylabel('Relative Delta-V error');
    grid on;
    title('Mass / trajectory Delta-V convergence');
end
end

function s=logical_text(value)
if value, s='yes'; else, s='no'; end
end
